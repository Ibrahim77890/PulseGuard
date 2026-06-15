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
    "compute.googleapis.com",
    "container.googleapis.com",
    "gkehub.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
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
