variable "project_id" {
  type        = string
  description = "The GCP project ID."
}

variable "environment" {
  type        = string
  description = "Environment label used in resource naming."
  default     = "dev"
}

variable "namespaces" {
  type        = list(string)
  description = "Namespaces that receive namespace-scoped GSAs and KSAs."
  default     = ["frontend", "backend", "data"]
}

variable "ksa_suffix" {
  type        = string
  description = "Suffix appended to the namespace name for the Kubernetes service account."
  default     = "app"
}
