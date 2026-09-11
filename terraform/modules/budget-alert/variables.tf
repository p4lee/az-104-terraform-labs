variable "name" {
  type        = string
  description = "Name of the budget."
}

variable "resource_group_id" {
  type        = string
  description = "Resource ID of the resource group this budget tracks spend for."
}

variable "amount" {
  type        = number
  description = "Monthly budget amount, in the subscription's billing currency."
}

variable "start_date" {
  type        = string
  description = "RFC3339 timestamp for the first day of the month the budget starts tracking from, e.g. \"2026-09-01T00:00:00Z\". Azure requires this to be the 1st of a month. This is a one-time anchor - it isn't meant to change after the budget is created."
}

variable "contact_emails" {
  type        = list(string)
  description = "Email addresses notified when a threshold is crossed."
}

variable "thresholds" {
  type        = list(number)
  description = "Percentages of the budget amount that trigger a notification, e.g. [50, 90]."
  default     = [50, 90]
}
