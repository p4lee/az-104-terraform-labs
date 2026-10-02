output "resource_group_name" {
  value       = module.resource_group.name
  description = "Name of the resource group created by this exercise."
}

output "app_default_hostname" {
  value       = azurerm_linux_web_app.this.default_hostname
  description = "Default hostname of the production app (<name>.azurewebsites.net)."
}

output "slot_default_hostname" {
  value       = azurerm_linux_web_app_slot.staging.default_hostname
  description = "Default hostname of the staging slot."
}

output "backup_storage_account" {
  value       = azurerm_storage_account.backup.name
  description = "Storage account holding the backup container."
}

# The provider marks this attribute sensitive, so the output has to say so.
# It is not really a secret - it goes into a public DNS TXT record - but
# Terraform refuses to surface a sensitive value without the annotation.
# Read it with: terraform output -raw custom_domain_verification_id
output "custom_domain_verification_id" {
  value       = azurerm_linux_web_app.this.custom_domain_verification_id
  description = "Value for the asuid TXT records that prove domain ownership before a hostname can be bound."
  sensitive   = true
}
