variable "location" {
  type        = string
  description = "Azure region for this exercise's resources."
  default     = "swedencentral"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group that holds the shared networking resources."
  default     = "rg-az104-networking"
}
