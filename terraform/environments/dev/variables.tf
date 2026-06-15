variable "project_id" {
  type        = string
  description = "GCP project ID for the dev environment."
}

variable "region" {
  type        = string
  description = "Primary GCP region for the dev environment."
  default     = "us-central1"
}

variable "environment" {
  type        = string
  description = "Environment label applied to in-cluster resources."
  default     = "dev"
}

variable "owner" {
  type        = string
  description = "Owner label applied to in-cluster resources."
  default     = "platform"
}

variable "cluster_name" {
  type        = string
  description = "Name of the GKE Autopilot cluster."
  default     = "pulseguard-dev"
}

variable "network" {
  type        = string
  description = "VPC network name or self link used by the cluster."
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork name or self link used by the cluster."
}

variable "cluster_secondary_range_name" {
  type        = string
  description = "Secondary IP range name for Pods."
}

variable "services_secondary_range_name" {
  type        = string
  description = "Secondary IP range name for Services."
}

variable "enable_private_nodes" {
  type        = bool
  description = "Whether the cluster uses private nodes."
  default     = true
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Whether to disable the public control plane endpoint."
  default     = true
}

variable "enable_binary_authorization" {
  type        = bool
  description = "Enable Binary Authorization support for the cluster and project policy."
  default     = true
}

variable "binary_authorization_evaluation_mode" {
  type        = string
  description = "Binary Authorization evaluation mode applied at the GKE cluster level."
  default     = "PROJECT_SINGLETON_POLICY_ENFORCE"
}

variable "enable_security_posture" {
  type        = bool
  description = "Enable GKE Security Posture configuration on the cluster."
  default     = true
}

variable "security_posture_mode" {
  type        = string
  description = "Off-cluster GKE Security Posture mode."
  default     = "BASIC"
}

variable "security_posture_vulnerability_mode" {
  type        = string
  description = "Workload vulnerability scanning mode for GKE Security Posture."
  default     = "VULNERABILITY_BASIC"
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "Private control plane CIDR block."
  default     = "172.16.0.0/28"
}

variable "release_channel" {
  type        = string
  description = "GKE release channel."
  default     = "REGULAR"
}

variable "namespaces" {
  type        = list(string)
  description = "Namespaces created for PulseGuard Phase 01."
  default     = ["frontend", "backend", "data"]
}

variable "observability_namespace" {
  type        = string
  description = "Namespace used for the observability stack in Phase 02."
  default     = "observability"
}

variable "gcp_api_list" {
  type        = list(string)
  description = "Required Google APIs for PulseGuard Phases 01 and 02."
  default = [
    "billingbudgets.googleapis.com",
    "bigquery.googleapis.com",
    "compute.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "container.googleapis.com",
    "cloudbilling.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "redis.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com",
    "gkehub.googleapis.com",
    "iam.googleapis.com",
    "mesh.googleapis.com",
    "monitoring.googleapis.com"
  ]
}

variable "grafana_admin_password" {
  type        = string
  description = "Grafana admin password for the kube-prometheus-stack release."
  default     = "change-me-in-tfvars"
  sensitive   = true
}

variable "grafana_storage_size" {
  type        = string
  description = "Persistent volume size for Grafana."
  default     = "10Gi"
}

variable "prometheus_storage_size" {
  type        = string
  description = "Persistent volume size for Prometheus."
  default     = "30Gi"
}

variable "loki_storage_size" {
  type        = string
  description = "Persistent volume size for Loki."
  default     = "30Gi"
}

variable "tempo_storage_size" {
  type        = string
  description = "Persistent volume size for Tempo."
  default     = "20Gi"
}

variable "kube_prometheus_stack_chart_version" {
  type        = string
  description = "Pinned Helm chart version for kube-prometheus-stack."
  default     = "61.3.2"
}

variable "loki_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Grafana Loki."
  default     = "6.10.0"
}

variable "tempo_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Grafana Tempo."
  default     = "1.10.1"
}

variable "promtail_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Grafana Promtail."
  default     = "6.16.6"
}

variable "otel_collector_chart_version" {
  type        = string
  description = "Pinned Helm chart version for the OpenTelemetry Collector."
  default     = "0.102.1"
}

variable "slo_services" {
  type        = list(string)
  description = "Services that receive Phase 03 SLO definitions."
  default     = ["frontend", "backend", "data"]
}

variable "slo_window_days" {
  type        = number
  description = "Rolling SLO window in days."
  default     = 30
}

variable "availability_goal" {
  type        = number
  description = "Availability SLO target as a ratio."
  default     = 0.995
}

variable "latency_goal" {
  type        = number
  description = "Latency SLO target as a ratio of requests under threshold."
  default     = 0.99
}

variable "latency_threshold_ms" {
  type        = number
  description = "Latency threshold in milliseconds for the latency SLO."
  default     = 500
}

variable "enable_google_monitoring_slos" {
  type        = bool
  description = "Create GCP-native uptime checks and SLO resources when service IDs and URLs are available."
  default     = false
}

variable "google_monitoring_service_ids" {
  type        = map(string)
  description = "Map of service name to Cloud Monitoring service resource ID for optional native SLOs."
  default     = {}
}

variable "uptime_check_urls" {
  type        = map(string)
  description = "Map of service name to external or internal URL used by Cloud Monitoring uptime checks."
  default     = {}
}

variable "uptime_check_path" {
  type        = string
  description = "HTTP path used for uptime checks when native Cloud Monitoring SLOs are enabled."
  default     = "/healthz"
}

variable "create_artifact_registry_repository" {
  type        = bool
  description = "Create the Artifact Registry repository used by the shift-left pipeline."
  default     = true
}

variable "artifact_registry_repository_id" {
  type        = string
  description = "Artifact Registry repository ID used for signed workload images."
  default     = "pulseguard-workloads"
}

variable "artifact_registry_repository_description" {
  type        = string
  description = "Description for the Artifact Registry repository."
  default     = "Signed PulseGuard workload images"
}

variable "binary_authorization_policy_description" {
  type        = string
  description = "Description for the project-level Binary Authorization policy."
  default     = "PulseGuard shift-left admission policy"
}

variable "binary_authorization_enforcement_mode" {
  type        = string
  description = "Binary Authorization enforcement mode for the default admission rule."
  default     = "DRYRUN_AUDIT_LOG_ONLY"
}

variable "binary_authorization_default_evaluation_mode" {
  type        = string
  description = "Default Binary Authorization evaluation mode when no attestor is configured."
  default     = "ALWAYS_ALLOW"
}

variable "attestor_name" {
  type        = string
  description = "Name of the Binary Authorization attestor."
  default     = "pulseguard-ci-attestor"
}

variable "attestor_note_name" {
  type        = string
  description = "Container Analysis note name used by the attestor."
  default     = "pulseguard-ci-attestor-note"
}

variable "attestor_note_hint" {
  type        = string
  description = "Human readable name stored in the attestation authority note."
  default     = "PulseGuard CI Attestor"
}

variable "attestor_public_keys" {
  type = list(object({
    id                  = optional(string)
    comment             = optional(string)
    public_key_pem      = string
    signature_algorithm = string
  }))
  description = "PKIX public keys trusted by the Binary Authorization attestor. Leave empty to keep the policy in allow mode until signing is configured."
  default     = []
}

variable "enable_falco" {
  type        = bool
  description = "Deploy Falco and Falcosidekick for runtime security detection."
  default     = true
}

variable "falco_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Falco."
  default     = "4.19.0"
}

variable "falco_sidekick_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Falcosidekick."
  default     = "0.8.3"
}

variable "falco_alert_topic_name" {
  type        = string
  description = "Pub/Sub topic name for Falco runtime alerts."
  default     = "pulseguard-falco-alerts"
}

variable "scc_findings_topic_name" {
  type        = string
  description = "Pub/Sub topic name for SCC finding notifications."
  default     = "pulseguard-scc-findings"
}

variable "security_alert_bucket_name" {
  type        = string
  description = "Cloud Storage bucket used to stage the runtime alert forwarding function source."
  default     = "pulseguard-security-alerts-src"
}

variable "security_alert_function_name" {
  type        = string
  description = "Cloud Function name used to forward runtime alerts into Cloud Logging."
  default     = "pulseguard-security-alert-forwarder"
}

variable "security_alert_function_runtime" {
  type        = string
  description = "Runtime for the runtime alert forwarding function."
  default     = "python312"
}

variable "security_alert_function_entry_point" {
  type        = string
  description = "Entry point for the runtime alert forwarding function."
  default     = "handle_pubsub"
}

variable "security_alert_metric_name" {
  type        = string
  description = "Log-based metric name for forwarded runtime security alerts."
  default     = "runtime_security_alert_events"
}

variable "security_alert_policy_display_name" {
  type        = string
  description = "Monitoring alert policy display name for runtime security alerts."
  default     = "PulseGuard Runtime Security Alerts"
}

variable "iam_drift_metric_name" {
  type        = string
  description = "Log-based metric name for IAM drift detection."
  default     = "iam_drift_events"
}

variable "iam_drift_alert_policy_display_name" {
  type        = string
  description = "Monitoring alert policy display name for IAM drift alerts."
  default     = "PulseGuard IAM Drift Detection"
}

variable "audit_logs_dataset_id" {
  type        = string
  description = "BigQuery dataset ID used for exported audit logs."
  default     = "pulseguard_audit_logs"
}

variable "audit_logs_sink_name" {
  type        = string
  description = "Logging sink name for audit-log export to BigQuery."
  default     = "pulseguard-audit-logs-sink"
}

variable "enable_scc_notification_config" {
  type        = bool
  description = "Enable org-level Security Command Center notification config."
  default     = false
}

variable "organization_id" {
  type        = string
  description = "GCP organization ID used for SCC notification config."
  default     = ""
}

variable "scc_notification_config_id" {
  type        = string
  description = "SCC notification config ID."
  default     = "pulseguard-scc-findings"
}

variable "scc_notification_filter" {
  type        = string
  description = "SCC findings filter for notification streaming."
  default     = "state = \"ACTIVE\" AND severity = \"HIGH\" OR severity = \"CRITICAL\""
}

variable "enable_chaos_mesh" {
  type        = bool
  description = "Deploy Chaos Mesh for Phase 06 incident engineering."
  default     = true
}

variable "chaos_mesh_namespace" {
  type        = string
  description = "Namespace used for Chaos Mesh."
  default     = "chaos-testing"
}

variable "chaos_mesh_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Chaos Mesh."
  default     = "2.8.0"
}

variable "chaos_mesh_dashboard_enabled" {
  type        = bool
  description = "Enable the Chaos Mesh dashboard."
  default     = false
}

variable "enable_gatekeeper" {
  type        = bool
  description = "Deploy Gatekeeper for Phase 07 compliance-as-code."
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
  default     = "3.16.1"
}

variable "enable_opencost" {
  type        = bool
  description = "Deploy OpenCost for Phase 07 cost observability."
  default     = true
}

variable "opencost_chart_version" {
  type        = string
  description = "Pinned Helm chart version for OpenCost."
  default     = "1.36.0"
}

variable "create_billing_export_dataset" {
  type        = bool
  description = "Create a BigQuery dataset reserved for Cloud Billing export."
  default     = true
}

variable "billing_export_dataset_id" {
  type        = string
  description = "BigQuery dataset ID used for Cloud Billing export."
  default     = "pulseguard_billing_export"
}

variable "enable_billing_budget" {
  type        = bool
  description = "Create an optional Cloud Billing budget when a billing account ID is available."
  default     = false
}

variable "billing_account_id" {
  type        = string
  description = "Billing account ID used for optional budget creation."
  default     = ""
}

variable "billing_budget_display_name" {
  type        = string
  description = "Display name for the optional Cloud Billing budget."
  default     = "PulseGuard Monthly Budget"
}

variable "billing_budget_currency" {
  type        = string
  description = "Currency code for the optional Cloud Billing budget."
  default     = "USD"
}

variable "billing_budget_amount_units" {
  type        = number
  description = "Whole-currency monthly amount for the optional Cloud Billing budget."
  default     = 300
}

variable "billing_budget_threshold_percents" {
  type        = list(number)
  description = "Threshold percentages for the optional Cloud Billing budget."
  default     = [0.5, 0.8, 1]
}

variable "aiops_service_name" {
  type        = string
  description = "Cloud Run service name for the Phase 08 AIOps assistant."
  default     = "pulseguard-aiops-assistant"
}

variable "aiops_service_image" {
  type        = string
  description = "Container image for the AIOps assistant."
  default     = "us-central1-docker.pkg.dev/my-gcp-project-id/pulseguard-workloads/aiops-assistant:latest"
}

variable "aiops_service_account_id" {
  type        = string
  description = "Service account ID for the AIOps assistant."
  default     = "pulseguard-aiops"
}

variable "aiops_ingress" {
  type        = string
  description = "Cloud Run ingress setting for the AIOps assistant."
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "aiops_timeout_seconds" {
  type        = number
  description = "Request timeout for the AIOps assistant."
  default     = 60
}

variable "aiops_min_instances" {
  type        = number
  description = "Minimum instances for the AIOps assistant."
  default     = 0
}

variable "aiops_max_instances" {
  type        = number
  description = "Maximum instances for the AIOps assistant."
  default     = 3
}

variable "aiops_cpu" {
  type        = string
  description = "CPU limit for the AIOps assistant."
  default     = "1"
}

variable "aiops_memory" {
  type        = string
  description = "Memory limit for the AIOps assistant."
  default     = "512Mi"
}

variable "aiops_allow_unauthenticated" {
  type        = bool
  description = "Allow unauthenticated access to the AIOps assistant."
  default     = true
}

variable "openrouter_api_key_secret_name" {
  type        = string
  description = "Secret Manager secret name used for the OpenRouter API key."
  default     = "pulseguard-openrouter-api-key"
}

variable "openrouter_api_key_secret_value" {
  type        = string
  description = "Optional secret value used to seed the OpenRouter API key."
  default     = ""
  sensitive   = true
}

variable "openrouter_base_url" {
  type        = string
  description = "OpenRouter base API URL."
  default     = "https://openrouter.ai/api/v1"
}

variable "openrouter_default_model" {
  type        = string
  description = "Default model route for the AIOps assistant."
  default     = "openai/gpt-4o-mini"
}

variable "openrouter_reasoning_model" {
  type        = string
  description = "Reasoning model route for deeper incident investigations."
  default     = "anthropic/claude-3.5-haiku"
}

variable "aiops_prometheus_base_url" {
  type        = string
  description = "Prometheus base URL used by the AIOps assistant."
  default     = "http://kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090"
}

variable "aiops_loki_base_url" {
  type        = string
  description = "Loki base URL used by the AIOps assistant."
  default     = "http://loki-gateway.observability.svc.cluster.local"
}

variable "aiops_grafana_base_url" {
  type        = string
  description = "Grafana base URL used by the AIOps assistant."
  default     = "http://grafana.observability.svc.cluster.local"
}

variable "aiops_enable_redis_memory" {
  type        = bool
  description = "Provision Redis-backed short-term memory for the AIOps assistant."
  default     = true
}

variable "aiops_redis_instance_name" {
  type        = string
  description = "Memorystore Redis instance name used by the AIOps assistant."
  default     = "pulseguard-aiops-memory"
}

variable "aiops_redis_memory_size_gb" {
  type        = number
  description = "Redis memory size in GB for the AIOps assistant."
  default     = 1
}

variable "aiops_redis_version" {
  type        = string
  description = "Redis version used by the AIOps assistant."
  default     = "REDIS_7_0"
}

variable "aiops_vpc_connector_name" {
  type        = string
  description = "VPC Access connector name used by the AIOps assistant."
  default     = "pulseguard-aiops-connector"
}

variable "aiops_vpc_connector_cidr" {
  type        = string
  description = "CIDR range reserved for the AIOps VPC Access connector."
  default     = "10.8.0.0/28"
}
