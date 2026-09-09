variable "scope" {
  type        = string
  description = "Resource ID of the scope the role is assigned at (management group, subscription, resource group, or resource)."
}

variable "role_definition_name" {
  type        = string
  description = "Name of the built-in Azure role to assign, e.g. \"Reader\", \"Contributor\"."
}

variable "principal_id" {
  type        = string
  description = "Object ID of the user, group, or service principal receiving the role."
}
