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

variable "gcp_api_list" {
  type        = list(string)
  description = "Required Google APIs for PulseGuard Phase 01."
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
