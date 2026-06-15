output "gatekeeper_namespace" {
  value       = var.enable_gatekeeper ? var.gatekeeper_namespace : null
  description = "Namespace hosting Gatekeeper."
}

output "billing_export_dataset" {
  value       = var.create_billing_export_dataset ? google_bigquery_dataset.billing_export[0].dataset_id : null
  description = "BigQuery dataset reserved for billing export data."
}

output "billing_budget_name" {
  value       = local.enable_billing_budget ? google_billing_budget.project_budget[0].name : null
  description = "Cloud Billing budget resource name when enabled."
}

output "opencost_release_name" {
  value       = var.enable_opencost ? "opencost" : null
  description = "Helm release name for OpenCost."
}
