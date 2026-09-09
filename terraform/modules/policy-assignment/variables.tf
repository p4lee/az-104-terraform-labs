variable "name" {
  type        = string
  description = "Name of the policy assignment."
}

variable "resource_group_id" {
  type        = string
  description = "Resource ID of the resource group the policy is assigned to."
}

variable "policy_definition_id" {
  type        = string
  description = "Resource ID of the policy (or policy set) definition being assigned."
}

variable "display_name" {
  type        = string
  description = "Display name shown in the Azure portal for this assignment."
  default     = null
}

variable "description" {
  type        = string
  description = "Description of why this policy is assigned."
  default     = null
}

variable "parameters" {
  type        = string
  description = "JSON-encoded parameters for the policy definition, if it takes any."
  default     = null
}
