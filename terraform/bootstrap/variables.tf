variable "resource_group_name" {
  type        = string
  description = "Resource group that holds the Terraform state storage account."
  default     = "rg-az104-tfstate"
}

variable "location" {
  type        = string
  description = "Azure region for the state storage account."
  default     = "swedencentral"
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique storage account name (lowercase letters/numbers only, 3-24 chars). No default on purpose - pick your own so it doesn't collide with someone else's."
}
