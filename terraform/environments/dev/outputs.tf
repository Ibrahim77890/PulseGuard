output "project_id" {
  value       = var.project_id
  description = "The GCP project used by the dev environment."
}

output "cluster_name" {
  value       = module.gke_autopilot.cluster_name
  description = "The GKE Autopilot cluster name."
}

output "cluster_location" {
  value       = var.region
  description = "The GKE Autopilot cluster location."
}

output "workload_pool" {
  value       = module.gke_autopilot.workload_pool
  description = "Workload Identity pool used by the cluster."
}

output "gsa_emails" {
  value       = module.workload_identity.gsa_emails
  description = "Namespace to Google service account mapping."
}

output "observability_namespace" {
  value       = module.observability_stack.namespace
  description = "Namespace where the Phase 02 observability stack is deployed."
}

output "grafana_service_name" {
  value       = module.observability_stack.grafana_service_name
  description = "Grafana service name exposed through an internal load balancer."
}

output "prometheus_service_name" {
  value       = module.observability_stack.prometheus_service_name
  description = "Prometheus service name inside the cluster."
}

output "loki_service_name" {
  value       = module.observability_stack.loki_service_name
  description = "Loki gateway service name inside the cluster."
}

output "tempo_service_name" {
  value       = module.observability_stack.tempo_service_name
  description = "Tempo service name inside the cluster."
}

output "otel_collector_service_name" {
  value       = module.observability_stack.otel_collector_service_name
  description = "OpenTelemetry Collector service name inside the cluster."
}

output "slo_services" {
  value       = module.slo_engineering.slo_services
  description = "Services covered by the Phase 03 SLO layer."
}

output "google_monitoring_slos_enabled" {
  value       = module.slo_engineering.google_monitoring_slos_enabled
  description = "Whether native Cloud Monitoring SLO resources are enabled."
}

output "artifact_registry_repository" {
  value       = module.security_pipeline.artifact_registry_repository
  description = "Artifact Registry repository used by the shift-left security pipeline."
}

output "binary_authorization_policy_mode" {
  value       = module.security_pipeline.policy_evaluation_mode
  description = "Effective Binary Authorization policy evaluation mode."
}

output "binary_authorization_attestor" {
  value       = module.security_pipeline.attestor_name
  description = "Binary Authorization attestor created for CI-signed images."
}

output "falco_alert_topic" {
  value       = module.runtime_security.falco_alert_topic
  description = "Pub/Sub topic receiving Falco runtime alerts."
}

output "scc_findings_topic" {
  value       = module.runtime_security.scc_findings_topic
  description = "Pub/Sub topic receiving SCC finding notifications."
}

output "audit_logs_dataset" {
  value       = module.runtime_security.audit_logs_dataset
  description = "BigQuery dataset receiving exported audit logs."
}

output "kubectl_get_credentials_command" {
  value       = "gcloud container clusters get-credentials ${module.gke_autopilot.cluster_name} --region ${var.region} --project ${var.project_id}"
  description = "Command to configure kubectl for the cluster."
}
