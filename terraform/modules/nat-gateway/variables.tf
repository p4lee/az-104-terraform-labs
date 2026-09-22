variable "name" {
  type        = string
  description = "Name of the NAT gateway. The public IP is named \"<name>-pip\"."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group the NAT gateway and its public IP are created in."
}

variable "location" {
  type        = string
  description = "Azure region for the NAT gateway."
}

variable "subnet_ids" {
  type        = map(string)
  description = "Subnets to attach the NAT gateway to, as { short-label = subnet-id }. A map rather than a list because for_each needs keys that are known at plan time, and subnet IDs aren't until the subnets exist."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the NAT gateway and its public IP."
  default     = {}
}
