variable "location" {
  type        = string
  description = "Azure region for this exercise's resources."
  default     = "swedencentral"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group created for this exercise."
  default     = "rg-az104-governance"
}

variable "budget_amount" {
  type        = number
  description = "Monthly budget amount (in your subscription's currency) for this exercise's resource group."
  default     = 20
}

variable "budget_start_date" {
  type        = string
  description = "RFC3339 timestamp for the 1st of the month this budget starts from. One-time anchor, not meant to change after creation."
  default     = "2026-09-01T00:00:00Z"
}

variable "budget_alert_email" {
  type        = string
  description = "Email address that receives budget threshold alerts. No default on purpose - set this in terraform.tfvars (gitignored) so your real email isn't hardcoded into public code."
}
