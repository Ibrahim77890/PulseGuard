variable "environment" {
  type        = string
  description = "Environment label used for naming and metadata."
  default     = "dev"
}

variable "namespace" {
  type        = string
  description = "Namespace where the observability stack is deployed."
  default     = "observability"
}

variable "grafana_admin_password" {
  type        = string
  description = "Grafana admin password."
  sensitive   = true
}

variable "grafana_dashboards" {
  type        = map(string)
  description = "Map of Grafana dashboard names to JSON payloads."
  default     = {}
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
}

variable "loki_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Grafana Loki."
}

variable "tempo_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Grafana Tempo."
}

variable "promtail_chart_version" {
  type        = string
  description = "Pinned Helm chart version for Grafana Promtail."
}

variable "otel_collector_chart_version" {
  type        = string
  description = "Pinned Helm chart version for the OpenTelemetry Collector."
}
