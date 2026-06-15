output "slo_services" {
  value       = var.slo_services
  description = "Services covered by the Phase 03 SLO configuration."
}

output "google_monitoring_slos_enabled" {
  value       = var.enable_google_monitoring_slos
  description = "Whether native Cloud Monitoring SLO resources are enabled."
}

output "google_monitoring_slo_names" {
  value       = keys(local.google_monitoring_services)
  description = "Services that have native Cloud Monitoring SLO resources configured."
}
