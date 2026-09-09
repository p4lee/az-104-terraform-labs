variable "location" {
  type        = string
  description = "Azure region for this exercise's resources."
  default     = "westeurope"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group created for this exercise."
  default     = "rg-az104-governance"
}
