output "cluster_name" {
  value       = google_container_cluster.autopilot.name
  description = "The name of the GKE Autopilot cluster."
}

output "cluster_endpoint" {
  value       = google_container_cluster.autopilot.endpoint
  description = "The IP address of the Kubernetes master endpoint."
}

output "cluster_ca_certificate" {
  value       = google_container_cluster.autopilot.master_auth[0].cluster_ca_certificate
  description = "The public certificate that is the root of trust for the cluster."
  sensitive   = true
}

output "workload_pool" {
  value       = google_container_cluster.autopilot.workload_identity_config[0].workload_pool
  description = "The workload pool identity string used for GCP IAM integration."
}
