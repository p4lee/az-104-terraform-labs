output "vm_id" {
  value       = azurerm_linux_virtual_machine.this.id
  description = "Resource ID of the virtual machine."
}

output "private_ip_address" {
  value       = azurerm_network_interface.this.private_ip_address
  description = "Private IP address of the VM's network interface."
}

output "data_disk_id" {
  value       = var.attach_data_disk ? azurerm_managed_disk.data[0].id : null
  description = "Resource ID of the optional data disk, if created."
}
