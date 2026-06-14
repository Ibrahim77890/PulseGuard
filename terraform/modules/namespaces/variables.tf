variable "environment" {
  type        = string
  description = "The environment name (e.g., dev, prod)."
  default     = "dev"
}

variable "owner" {
  type        = string
  description = "The team responsible for these namespaces."
  default     = "platform"
}

variable "namespaces" {
  type        = list(string)
  description = "List of namespaces to create."
  default     = ["frontend", "backend", "data"]
}