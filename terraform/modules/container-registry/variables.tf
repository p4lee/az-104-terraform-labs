variable "name" {
  type        = string
  description = "Registry name. Must be globally unique, 5-50 alphanumeric characters, no hyphens."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group the registry is created in."
}

variable "location" {
  type        = string
  description = "Azure region for the registry."
}

variable "sku" {
  type        = string
  description = "Registry SKU. Basic is the cheapest and enough for a lab; Premium adds geo-replication, private endpoints and content trust."
  default     = "Basic"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the registry."
  default     = {}
}
