output "project_id" {
  value       = var.project_id
  description = "The GCP project used by the dev environment."
}

output "cluster_name" {
  value       = module.gke_autopilot.cluster_name
  description = "The GKE Autopilot cluster name."
}

output "cluster_location" {
  value       = var.region
  description = "The GKE Autopilot cluster location."
}

output "workload_pool" {
  value       = module.gke_autopilot.workload_pool
  description = "Workload Identity pool used by the cluster."
}

output "gsa_emails" {
  value       = module.workload_identity.gsa_emails
  description = "Namespace to Google service account mapping."
}

output "kubectl_get_credentials_command" {
  value       = "gcloud container clusters get-credentials ${module.gke_autopilot.cluster_name} --region ${var.region} --project ${var.project_id}"
  description = "Command to configure kubectl for the cluster."
}
