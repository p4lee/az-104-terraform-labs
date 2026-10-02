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

variable "dns_zone_name" {
  type        = string
  description = "Public DNS zone for the lab domain. The registrar's nameservers must be changed to Azure's for this zone to become authoritative."
  default     = "cloud-consult-lab.site"
}
