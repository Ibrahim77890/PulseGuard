variable "namespaces" {
  type        = list(string)
  default     = ["frontend", "backend", "data"]
  description = "Namespaces to apply RBAC roles within."
}