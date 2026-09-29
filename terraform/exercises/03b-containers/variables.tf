variable "location" {
  type        = string
  description = "Azure region for this exercise's resources."
  default     = "swedencentral"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group created for this exercise."
  default     = "rg-az104-containers"
}

variable "acr_name" {
  type        = string
  description = "Container registry name. Globally unique, 5-50 alphanumeric characters, no hyphens. No default on purpose - set it in terraform.tfvars."
}

variable "aci_dns_label" {
  type        = string
  description = "DNS label for the container instance's public IP. Must be unique within the region; the FQDN becomes <label>.<region>.azurecontainer.io."
}

variable "image_name" {
  type        = string
  description = "Image repository name inside the registry."
  default     = "az104-web"
}

variable "image_tag" {
  type        = string
  description = "Image tag. Bump this when you rebuild with az acr build to force a new pull."
  default     = "v1"
}
