variable "location" {
  type        = string
  description = "Azure region for this exercise's resources."
  default     = "swedencentral"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group created for this exercise."
  default     = "rg-az104-appservice"
}

variable "app_name" {
  type        = string
  description = "Web app name. Globally unique - becomes <name>.azurewebsites.net. No default on purpose; set it in terraform.tfvars."
}

variable "backup_storage_account_name" {
  type        = string
  description = "Storage account for App Service backups. Globally unique, 3-24 lowercase alphanumeric characters."
}

variable "sku_name" {
  type        = string
  description = "App Service plan SKU. S1 (Standard) is the cheapest tier that supports deployment slots, autoscale rules and backup. F1/B1 do not."
  default     = "S1"
}

variable "state_resource_group_name" {
  type        = string
  description = "Resource group of the Terraform state storage account (bootstrap output). Needed to read exercise 04's DNS zone outputs."
}

variable "state_storage_account_name" {
  type        = string
  description = "Name of the Terraform state storage account (bootstrap output)."
}

variable "enable_custom_domain" {
  type        = bool
  description = "Phase 2 switch. Leave false until the app exists and app_inbound_ip is known, then set true to create the DNS records, hostname bindings and TLS certificates."
  default     = false
}

variable "app_inbound_ip" {
  type        = string
  description = "The web app's inbound IP, from: az webapp show -g <rg> -n <app> --query inboundIpAddress -o tsv. Needed for the apex A record, because Azure DNS alias records don't support App Service. Ignored while enable_custom_domain is false."
  default     = ""
}

variable "subdomain" {
  type        = string
  description = "Subdomain bound alongside the apex, as a CNAME."
  default     = "www"
}
