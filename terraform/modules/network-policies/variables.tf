variable "namespaces" {
  type    = list(string)
  default = ["frontend", "backend", "data"]
}

variable "observability_namespace" {
  type        = string
  description = "Namespace that hosts the observability stack and needs telemetry access to application namespaces."
  default     = "observability"
}
