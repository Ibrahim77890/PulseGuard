variable "observability_namespace" {
  type        = string
  description = "Namespace used by the platform observability stack."
  default     = "observability"
}

variable "chaos_mesh_namespace" {
  type        = string
  description = "Namespace used for Chaos Mesh."
  default     = "chaos-testing"
}

variable "enable_chaos_mesh" {
  type        = bool
  description = "Deploy Chaos Mesh."
  default     = true
}

variable "chaos_mesh_chart_version" {
  type        = string
  description = "Helm chart version for Chaos Mesh."
}

variable "chaos_mesh_dashboard_enabled" {
  type        = bool
  description = "Enable the Chaos Mesh dashboard."
  default     = false
}
