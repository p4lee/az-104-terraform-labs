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

variable "subnet_name" {
  type        = string
  description = "Name of the subnet created inside the virtual network."
}

variable "subnet_address_prefix" {
  type        = list(string)
  description = "Address prefix(es) for the subnet, e.g. [\"10.0.1.0/24\"]."
}
