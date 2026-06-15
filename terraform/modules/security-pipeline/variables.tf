variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "region" {
  type        = string
  description = "Primary GCP region for Artifact Registry."
}

variable "create_artifact_registry_repository" {
  type        = bool
  description = "Create the Artifact Registry repository for PulseGuard workload images."
  default     = true
}

variable "artifact_registry_repository_id" {
  type        = string
  description = "Artifact Registry repository ID."
  default     = "pulseguard-workloads"
}

variable "artifact_registry_repository_description" {
  type        = string
  description = "Description of the Artifact Registry repository."
  default     = "Signed PulseGuard workload images"
}

variable "enable_binary_authorization" {
  type        = bool
  description = "Create Binary Authorization resources."
  default     = true
}

variable "binary_authorization_policy_description" {
  type        = string
  description = "Description for the project-level Binary Authorization policy."
  default     = "PulseGuard shift-left admission policy"
}

variable "binary_authorization_enforcement_mode" {
  type        = string
  description = "Enforcement mode for Binary Authorization default admission rule."
  default     = "DRYRUN_AUDIT_LOG_ONLY"
}

variable "binary_authorization_default_evaluation_mode" {
  type        = string
  description = "Default evaluation mode when no attestor public keys are configured."
  default     = "ALWAYS_ALLOW"
}

variable "attestor_name" {
  type        = string
  description = "Binary Authorization attestor name."
  default     = "pulseguard-ci-attestor"
}

variable "attestor_note_name" {
  type        = string
  description = "Container Analysis note name backing the attestor."
  default     = "pulseguard-ci-attestor-note"
}

variable "attestor_note_hint" {
  type        = string
  description = "Human readable attestation authority hint."
  default     = "PulseGuard CI Attestor"
}

variable "attestor_public_keys" {
  type = list(object({
    id                  = optional(string)
    comment             = optional(string)
    public_key_pem      = string
    signature_algorithm = string
  }))
  description = "Public keys trusted by the Binary Authorization attestor."
  default     = []
}
