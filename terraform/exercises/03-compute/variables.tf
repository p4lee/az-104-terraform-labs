variable "location" {
  type        = string
  description = "Azure region for this exercise's resources."
  default     = "swedencentral"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group created for this exercise."
  default     = "rg-az104-compute"
}

variable "vm_size" {
  type        = string
  description = "VM size. Standard_B2ats_v2 (AMD, x64) qualifies for the Azure free account's 750 free hours/month when paired with a 64 GiB Premium SSD OS disk."
  default     = "Standard_B2ats_v2"
}

variable "vm_zone" {
  type        = string
  description = "Availability zone for the VM."
  default     = "1"
}

variable "admin_username" {
  type        = string
  description = "Admin username for SSH login to the VM."
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  type        = string
  description = "Your SSH public key contents (e.g. from az104-vm.pub). No default on purpose - set this in terraform.tfvars (gitignored)."
}
