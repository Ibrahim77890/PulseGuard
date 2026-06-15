variable "project_id" {
  type        = string
  description = "GCP project ID used for compliance and cost resources."
}

variable "region" {
  type        = string
  description = "Primary GCP region."
}

variable "cluster_name" {
  type        = string
  description = "Cluster name used by cost tools."
}

variable "observability_namespace" {
  type        = string
  description = "Namespace hosting the observability stack."
  default     = "observability"
}

variable "enable_gatekeeper" {
  type        = bool
  description = "Deploy Gatekeeper for compliance-as-code."
  default     = true
}

variable "gatekeeper_namespace" {
  type        = string
  description = "Namespace used for Gatekeeper."
  default     = "gatekeeper-system"
}

variable "gatekeeper_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Gatekeeper."
}

variable "enable_opencost" {
  type        = bool
  description = "Deploy OpenCost into the observability namespace."
  default     = true
}

variable "opencost_chart_version" {
  type        = string
  description = "Pinned Helm chart version for OpenCost."
}

variable "create_billing_export_dataset" {
  type        = bool
  description = "Create a BigQuery dataset for Cloud Billing exports."
  default     = true
}

variable "billing_export_dataset_id" {
  type        = string
  description = "BigQuery dataset ID used for Cloud Billing exports."
  default     = "pulseguard_billing_export"
}

variable "enable_billing_budget" {
  type        = bool
  description = "Create a billing budget for the project when a billing account ID is provided."
  default     = false
}

variable "billing_account_id" {
  type        = string
  description = "Billing account ID used for budget creation."
  default     = ""
}

variable "billing_budget_display_name" {
  type        = string
  description = "Display name for the Cloud Billing budget."
  default     = "PulseGuard Monthly Budget"
}

variable "billing_budget_currency" {
  type        = string
  description = "Currency code for the billing budget."
  default     = "USD"
}

variable "billing_budget_amount_units" {
  type        = number
  description = "Whole-currency monthly budget amount."
  default     = 300
}

variable "billing_budget_threshold_percents" {
  type        = list(number)
  description = "Threshold percentages used for the Cloud Billing budget."
  default     = [0.5, 0.8, 1]
}
