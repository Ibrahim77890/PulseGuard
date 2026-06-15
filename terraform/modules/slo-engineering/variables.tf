variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "environment" {
  type        = string
  description = "Environment label for naming."
  default     = "dev"
}

variable "slo_services" {
  type        = list(string)
  description = "Services covered by Phase 03."
  default     = ["frontend", "backend", "data"]
}

variable "slo_window_days" {
  type        = number
  description = "Rolling SLO window in days."
  default     = 30
}

variable "availability_goal" {
  type        = number
  description = "Availability SLO target ratio."
  default     = 0.995
}

variable "latency_goal" {
  type        = number
  description = "Latency SLO target ratio."
  default     = 0.99
}

variable "latency_threshold_ms" {
  type        = number
  description = "Latency threshold in milliseconds."
  default     = 500
}

variable "enable_google_monitoring_slos" {
  type        = bool
  description = "Create GCP-native SLO resources."
  default     = false
}

variable "google_monitoring_service_ids" {
  type        = map(string)
  description = "Map of service name to Cloud Monitoring service ID or full resource path."
  default     = {}
}

variable "uptime_check_urls" {
  type        = map(string)
  description = "Map of service name to uptime-check URL."
  default     = {}
}

variable "uptime_check_path" {
  type        = string
  description = "HTTP path used for uptime checks."
  default     = "/healthz"
}
