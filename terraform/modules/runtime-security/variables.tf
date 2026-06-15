variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "region" {
  type        = string
  description = "Primary GCP region."
}

variable "observability_namespace" {
  type        = string
  description = "Namespace used for observability and runtime security workloads."
  default     = "observability"
}

variable "enable_falco" {
  type        = bool
  description = "Deploy Falco and Falcosidekick."
  default     = true
}

variable "falco_chart_version" {
  type        = string
  description = "Helm chart version for Falco."
}

variable "falco_sidekick_chart_version" {
  type        = string
  description = "Helm chart version for Falcosidekick."
}

variable "falco_alert_topic_name" {
  type        = string
  description = "Pub/Sub topic name for Falco runtime alerts."
}

variable "scc_findings_topic_name" {
  type        = string
  description = "Pub/Sub topic name for SCC finding notifications."
}

variable "security_alert_bucket_name" {
  type        = string
  description = "Cloud Storage bucket name used for the runtime alert forwarder source."
}

variable "security_alert_function_name" {
  type        = string
  description = "Cloud Function name used for runtime alert forwarding."
}

variable "security_alert_function_runtime" {
  type        = string
  description = "Runtime used by the runtime alert forwarding function."
}

variable "security_alert_function_entry_point" {
  type        = string
  description = "Entry point for the runtime alert forwarding function."
}

variable "security_alert_metric_name" {
  type        = string
  description = "Log-based metric name for forwarded runtime security alerts."
}

variable "security_alert_policy_display_name" {
  type        = string
  description = "Display name for the runtime security alert policy."
}

variable "iam_drift_metric_name" {
  type        = string
  description = "Log-based metric name for IAM drift detection."
}

variable "iam_drift_alert_policy_display_name" {
  type        = string
  description = "Display name for the IAM drift alert policy."
}

variable "audit_logs_dataset_id" {
  type        = string
  description = "BigQuery dataset ID for audit log export."
}

variable "audit_logs_sink_name" {
  type        = string
  description = "Logging sink name for audit-log export."
}

variable "enable_scc_notification_config" {
  type        = bool
  description = "Enable org-level SCC notification config."
  default     = false
}

variable "organization_id" {
  type        = string
  description = "GCP organization ID for SCC notifications."
  default     = ""
}

variable "scc_notification_config_id" {
  type        = string
  description = "SCC notification config ID."
}

variable "scc_notification_filter" {
  type        = string
  description = "Filter used by the SCC notification config."
}
