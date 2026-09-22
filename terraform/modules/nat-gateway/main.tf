# Static public IP the NAT gateway uses for all outbound traffic.
# Zones set explicitly: Azure now makes Standard public IPs zone-redundant
# by default, so declaring ["1","2","3"] keeps Terraform's view in sync
# with what Azure actually creates (no drift on the next plan).
resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

# Standard SKU, "no zone" - Azure picks the zone. Fine for a lab; for
# production zone redundancy, the newer StandardV2 SKU is the option.
resource "azurerm_nat_gateway" "this" {
  name                    = var.name
  resource_group_name     = var.resource_group_name
  location                = var.location
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.this.id
}

# Once attached, the NAT gateway becomes the subnet's default route to the
# internet - no route tables needed.
resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each = var.subnet_ids

  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.this.id
}
