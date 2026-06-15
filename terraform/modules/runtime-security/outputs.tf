output "falco_alert_topic" {
  value       = google_pubsub_topic.falco_alerts.id
  description = "Pub/Sub topic receiving Falco runtime alerts."
}

output "scc_findings_topic" {
  value       = google_pubsub_topic.scc_findings.id
  description = "Pub/Sub topic receiving SCC finding notifications."
}

output "audit_logs_dataset" {
  value       = google_bigquery_dataset.audit_logs.id
  description = "BigQuery dataset receiving exported audit logs."
}

output "runtime_security_function" {
  value       = google_cloudfunctions2_function.security_alert_forwarder.name
  description = "Cloud Function that forwards runtime security alerts."
}
