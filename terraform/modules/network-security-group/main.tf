resource "azurerm_network_security_group" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  # Intentionally no custom rules here. Azure's built-in default rules
  # already allow VNet-internal traffic and deny all inbound internet
  # traffic, which is exactly right for a VM with no public IP. Custom
  # allow/deny rules are exercise 04's job.
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.this.id
}
