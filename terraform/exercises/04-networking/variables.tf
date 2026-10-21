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

variable "enable_nat_gateway" {
  type        = bool
  description = "Whether to deploy the NAT gateway and its public IP (~EUR 1/day). Set to false when no compute is running in these subnets; the VNet, subnets, NSGs and DNS zone are free and stay either way."
  default     = true
}
