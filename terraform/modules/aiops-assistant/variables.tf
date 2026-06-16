variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "region" {
  type        = string
  description = "Primary deployment region."
}

variable "network" {
  type        = string
  description = "VPC network used by the assistant."
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork used by the assistant."
}

variable "aiops_service_name" {
  type        = string
  description = "Cloud Run service name for the AIOps assistant."
  default     = "pulseguard-aiops-assistant"
}

variable "aiops_service_image" {
  type        = string
  description = "Container image for the AIOps assistant Cloud Run service."
}

variable "aiops_service_account_id" {
  type        = string
  description = "Service account ID for the AIOps assistant."
  default     = "pulseguard-aiops"
}

variable "aiops_ingress" {
  type        = string
  description = "Cloud Run ingress setting."
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "aiops_timeout_seconds" {
  type        = number
  description = "Request timeout for the Cloud Run service."
  default     = 60
}

variable "aiops_min_instances" {
  type        = number
  description = "Minimum Cloud Run instances."
  default     = 0
}

variable "aiops_max_instances" {
  type        = number
  description = "Maximum Cloud Run instances."
  default     = 3
}

variable "aiops_cpu" {
  type        = string
  description = "CPU limit for the Cloud Run service."
  default     = "1"
}

variable "aiops_memory" {
  type        = string
  description = "Memory limit for the Cloud Run service."
  default     = "512Mi"
}

variable "allow_unauthenticated" {
  type        = bool
  description = "Allow unauthenticated access to the AIOps assistant."
  default     = true
}

variable "openrouter_api_key_secret_name" {
  type        = string
  description = "Secret Manager secret name holding the OpenRouter API key."
  default     = "pulseguard-openrouter-api-key"
}

variable "openrouter_api_key_secret_value" {
  type        = string
  description = "Optional secret value used to seed the OpenRouter API key secret."
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
  description = "Default model route for the assistant."
  default     = "openai/gpt-4o-mini"
}

variable "openrouter_reasoning_model" {
  type        = string
  description = "Model route for deeper investigations."
  default     = "anthropic/claude-3.5-haiku"
}

variable "prometheus_base_url" {
  type        = string
  description = "Base URL for Prometheus."
  default     = "http://kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090"
}

variable "loki_base_url" {
  type        = string
  description = "Base URL for Loki."
  default     = "http://loki-gateway.observability.svc.cluster.local"
}

variable "grafana_base_url" {
  type        = string
  description = "Base URL for Grafana."
  default     = "http://grafana.observability.svc.cluster.local"
}

variable "otel_exporter_otlp_endpoint" {
  type        = string
  description = "OTLP HTTP endpoint used by the assistant for GenAI traces."
  default     = ""
}

variable "eval_results_path" {
  type        = string
  description = "Path to the latest eval results JSON inside the assistant container."
  default     = "/app/evals/latest-results.json"
}

variable "model_pricing_usd_per_million" {
  type = map(object({
    input  = number
    output = number
  }))
  description = "Per-model token pricing used for cost estimation."
  default = {
    default = {
      input  = 0.15
      output = 0.6
    }
    "openai/gpt-4o-mini" = {
      input  = 0.15
      output = 0.6
    }
    "anthropic/claude-3.5-haiku" = {
      input  = 0.8
      output = 4.0
    }
  }
}

variable "enable_redis_memory" {
  type        = bool
  description = "Provision Memorystore Redis and use it for short-term session memory."
  default     = true
}

variable "redis_instance_name" {
  type        = string
  description = "Memorystore Redis instance name."
  default     = "pulseguard-aiops-memory"
}

variable "redis_memory_size_gb" {
  type        = number
  description = "Memorystore size in GB."
  default     = 1
}

variable "redis_version" {
  type        = string
  description = "Memorystore Redis version."
  default     = "REDIS_7_0"
}

variable "aiops_vpc_connector_name" {
  type        = string
  description = "VPC Access connector name for the assistant."
  default     = "pulseguard-aiops-connector"
}

variable "aiops_vpc_connector_cidr" {
  type        = string
  description = "CIDR range reserved for the VPC Access connector."
  default     = "10.8.0.0/28"
}
