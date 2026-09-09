output "resource_group_name" {
  value       = azurerm_resource_group.state.name
  description = "Pass this as -backend-config=\"resource_group_name=...\" when initializing exercise configs."
}

output "storage_account_name" {
  value       = azurerm_storage_account.state.name
  description = "Pass this as -backend-config=\"storage_account_name=...\" when initializing exercise configs."
}

output "container_name" {
  value       = azurerm_storage_container.state.name
  description = "Pass this as -backend-config=\"container_name=...\" when initializing exercise configs."
}
