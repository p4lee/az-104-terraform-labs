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

variable "vmss_size" {
  type        = string
  description = "VM size for scale set instances. Standard_B2ats_v2 is used because Standard_B1s isn't offered in swedencentral; it shares the Basv2 vCPU quota with the single VM."
  default     = "Standard_B2ats_v2"
}

variable "vmss_instance_count" {
  type        = number
  description = "Scale set instances at creation. Starts at 1 so autoscale has room to scale out within the free-trial vCPU quota."
  default     = 1
}

variable "deploy_single_vm" {
  type        = bool
  description = "Whether to deploy the single VM. Set to false to free its 2 vCPUs of quota (deallocated VMs still count against quota)."
  default     = true
}

variable "state_resource_group_name" {
  type        = string
  description = "Resource group of the Terraform state storage account (bootstrap output). Needed to read exercise 04's outputs - a config can't read its own backend settings, so this repeats the -backend-config value."
}

variable "state_storage_account_name" {
  type        = string
  description = "Name of the Terraform state storage account (bootstrap output). Same value as the -backend-config used at init."
}

variable "vmss_zones" {
  type        = list(string)
  description = "Availability zones the scale set may place instances in. All three zones give Azure the most room to find capacity; narrow this only if you need to."
  default     = ["1", "2", "3"]
}
