variable "name" {
  type        = string
  description = "Name of the network security group."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group the NSG is created in."
}

variable "location" {
  type        = string
  description = "Azure region for the NSG."
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the subnet this NSG is associated with."
}
