output "resource_group_name" {
  value       = module.resource_group.name
  description = "Name of the resource group created by this exercise."
}

output "vm_id" {
  value       = module.vm.vm_id
  description = "Resource ID of the VM."
}

output "vm_private_ip" {
  value       = module.vm.private_ip_address
  description = "Private IP address of the VM."
}

output "data_disk_id" {
  value       = module.vm.data_disk_id
  description = "Resource ID of the optional data disk."
}
