variable "project_id" {
  type        = string
  description = "The ID of the GCP project where the GKE cluster will be created."
}

variable "cluster_name" {
  type        = string
  description = "The name of the GKE Autopilot cluster."
}

variable "region" {
  type        = string
  description = "The region to host the cluster in."
}

variable "network" {
  type        = string
  description = "The VPC network name or self_link."
}

variable "subnetwork" {
  type        = string
  description = "The subnetwork name or self_link."
}

variable "cluster_secondary_range_name" {
  type        = string
  description = "The name of the secondary range in the subnet to use for IP aliasing (Pods)."
}

variable "services_secondary_range_name" {
  type        = string
  description = "The name of the secondary range in the subnet to use for Services."
}

variable "enable_private_nodes" {
  type        = bool
  description = "Control whether nodes have internal IP addresses only."
  default     = true
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "The IP range in CIDR notation to use for the hosted master network. Required if enable_private_nodes is true."
  default     = "172.16.0.0/28"
}

variable "release_channel" {
  type        = string
  description = "The release channel for this cluster. Accepted values: RAPID, REGULAR, STABLE."
  default     = "REGULAR"
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Disable the public control plane endpoint when true."
  default     = true
}

variable "resource_labels" {
  type        = map(string)
  description = "Labels applied to the GKE cluster."
  default     = {}
}

variable "enable_binary_authorization" {
  type        = bool
  description = "Enable Binary Authorization configuration on the cluster."
  default     = true
}

variable "binary_authorization_evaluation_mode" {
  type        = string
  description = "Binary Authorization evaluation mode applied at cluster level."
  default     = "PROJECT_SINGLETON_POLICY_ENFORCE"
}

variable "enable_security_posture" {
  type        = bool
  description = "Enable GKE Security Posture configuration."
  default     = true
}

variable "security_posture_mode" {
  type        = string
  description = "Off-cluster security posture mode."
  default     = "BASIC"
}

variable "security_posture_vulnerability_mode" {
  type        = string
  description = "Vulnerability scanning mode for security posture."
  default     = "VULNERABILITY_BASIC"
}
