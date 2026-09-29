output "resource_group_name" {
  value       = module.resource_group.name
  description = "Name of the resource group created by this exercise."
}

output "acr_login_server" {
  value       = module.registry.login_server
  description = "Registry hostname. Use it with az acr build and to tag images."
}

output "aci_fqdn" {
  value       = azurerm_container_group.aci.fqdn
  description = "Public FQDN of the container instance."
}

output "container_app_fqdn" {
  value       = azurerm_container_app.app.latest_revision_fqdn
  description = "Public FQDN of the container app's latest revision."
}
