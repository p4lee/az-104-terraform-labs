output "resource_group_name" {
  value       = module.resource_group.name
  description = "Name of the resource group created by this exercise."
}

output "resource_group_id" {
  value       = module.resource_group.id
  description = "Resource ID of the resource group created by this exercise."
}

output "policy_assignment_id" {
  value       = module.require_tag_policy.id
  description = "Resource ID of the tag-enforcement policy assignment."
}

output "budget_id" {
  value       = module.budget.id
  description = "Resource ID of the cost management budget."
}
