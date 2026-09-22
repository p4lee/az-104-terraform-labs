# These outputs are the "contract" other exercises read through
# terraform_remote_state (e.g. 03-compute reads subnet_ids).

output "resource_group_name" {
  value       = module.resource_group.name
  description = "Name of the networking resource group."
}

output "vnet_id" {
  value       = module.vnet_workload.vnet_id
  description = "Resource ID of the workload virtual network."
}

output "vnet_name" {
  value       = module.vnet_workload.name
  description = "Name of the workload virtual network."
}

output "subnet_ids" {
  value       = module.vnet_workload.subnet_ids
  description = "Map of subnet name to subnet resource ID."
}

output "nat_public_ip" {
  value       = module.nat_gateway.public_ip_address
  description = "Public IP that outbound traffic from both subnets uses."
}
