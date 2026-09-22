resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value

  # Private subnet: no implicit "default outbound" public IP. Anything that
  # needs the internet must use an explicit method - here, the NAT gateway.
  # Same as Azure's default for new VNets since March 2026.
  default_outbound_access_enabled = false
}
