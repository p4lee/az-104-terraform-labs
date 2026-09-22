output "vmss_id" {
  value       = azurerm_orchestrated_virtual_machine_scale_set.this.id
  description = "Resource ID of the virtual machine scale set."
}

output "vmss_name" {
  value       = azurerm_orchestrated_virtual_machine_scale_set.this.name
  description = "Name of the virtual machine scale set."
}
