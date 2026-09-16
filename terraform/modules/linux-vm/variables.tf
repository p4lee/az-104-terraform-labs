variable "name" {
  type        = string
  description = "Name of the virtual machine."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group the VM is created in."
}

variable "location" {
  type        = string
  description = "Azure region for the VM."
}

variable "zone" {
  type        = string
  description = "Availability zone to deploy the VM into, e.g. \"1\"."
}

variable "size" {
  type        = string
  description = "VM size, e.g. \"Standard_B2ats_v2\"."
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the subnet the VM's network interface attaches to."
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
  description = "Whether to encrypt temp/cache/OS disks at the host. Requires the EncryptionAtHost feature to be registered on the subscription first."
  default     = true
}

variable "attach_data_disk" {
  type        = bool
  description = "Whether to create and attach a small extra managed data disk, to demonstrate disk management separately from the OS disk."
  default     = true
}

variable "data_disk_size_gb" {
  type        = number
  description = "Size of the optional data disk, in GiB."
  default     = 4
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the VM."
  default     = {}
}
