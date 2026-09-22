variable "name" {
  type        = string
  description = "Name of the virtual network."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group the virtual network is created in."
}

variable "location" {
  type        = string
  description = "Azure region for the virtual network."
}

variable "address_space" {
  type        = list(string)
  description = "Address space for the virtual network, e.g. [\"10.0.0.0/16\"]."
}

variable "subnets" {
  type        = map(list(string))
  description = "Subnets to create, as { subnet-name = [address prefixes] }, e.g. { \"snet-vms\" = [\"10.0.1.0/24\"] }."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the virtual network."
  default     = {}
}
