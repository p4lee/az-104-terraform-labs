resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  # No admin user. Pulls authenticate with a managed identity holding the
  # AcrPull role instead of a stored username/password - the same reason
  # exercise 01 assigns roles rather than handing out keys.
  admin_enabled = false

  tags = var.tags
}
