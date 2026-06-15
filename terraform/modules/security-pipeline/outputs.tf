output "artifact_registry_repository" {
  value       = var.create_artifact_registry_repository ? google_artifact_registry_repository.workloads[0].name : null
  description = "Artifact Registry repository name."
}

output "artifact_registry_repository_url" {
  value       = var.create_artifact_registry_repository ? "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repository_id}" : null
  description = "Artifact Registry repository URL prefix."
}

output "policy_evaluation_mode" {
  value       = local.evaluation_mode
  description = "Effective Binary Authorization policy evaluation mode."
}

output "attestor_name" {
  value       = local.attestor_enabled ? google_binary_authorization_attestor.ci[0].name : null
  description = "Binary Authorization attestor resource name."
}
