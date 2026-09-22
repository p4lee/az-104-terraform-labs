# one(...) returns null when the single VM is switched off
# (deploy_single_vm = false) instead of failing.

output "resource_group_name" {
  value       = module.resource_group.name
  description = "Name of the resource group created by this exercise."
}

output "vm_id" {
  value       = one(module.vm[*].vm_id)
  description = "Resource ID of the VM (null if deploy_single_vm is false)."
}

output "vm_private_ip" {
  value       = one(module.vm[*].private_ip_address)
  description = "Private IP address of the VM (null if deploy_single_vm is false)."
}

output "data_disk_id" {
  value       = one(module.vm[*].data_disk_id)
  description = "Resource ID of the optional data disk (null if deploy_single_vm is false)."
}

output "vmss_id" {
  value       = module.vmss.vmss_id
  description = "Resource ID of the virtual machine scale set."
}

output "vmss_name" {
  value       = module.vmss.vmss_name
  description = "Name of the virtual machine scale set."
}
