variable "name" {
  type        = string
  description = "Name of the virtual machine scale set."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group the scale set is created in."
}

variable "location" {
  type        = string
  description = "Azure region for the scale set."
}

variable "size" {
  type        = string
  description = "VM size used for every instance, e.g. \"Standard_B2ats_v2\"."
}

variable "instance_count" {
  type        = number
  description = "Number of instances at creation. Also used as autoscale's default capacity. Later changes are ignored so autoscale can own the count."
  default     = 1
}

variable "zones" {
  type        = list(string)
  description = "Availability zones the instances are spread across."
  default     = ["1", "2"]
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the subnet the instances' network interfaces attach to."
}

variable "admin_username" {
  type        = string
  description = "Admin username for SSH login."
}

variable "admin_ssh_public_key" {
  type        = string
  description = "Public key (contents of your .pub file) used for SSH login. No password auth is configured."
}

variable "encryption_at_host_enabled" {
  type        = bool
  description = "Whether to encrypt temp/cache/OS disks at the host. Requires the EncryptionAtHost feature on the subscription and a VM size that supports it."
  default     = true
}

variable "autoscale_enabled" {
  type        = bool
  description = "Whether to create a CPU-based autoscale setting for the scale set."
  default     = true
}

variable "autoscale_min" {
  type        = number
  description = "Minimum instance count autoscale can scale in to."
  default     = 1
}

variable "autoscale_max" {
  type        = number
  description = "Maximum instance count autoscale can scale out to. Keep this within your regional vCPU quota."
  default     = 2
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the scale set."
  default     = {}
}
