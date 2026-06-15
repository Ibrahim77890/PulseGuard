output "service_url" {
  value       = google_cloud_run_v2_service.aiops.uri
  description = "URL for the AIOps assistant service."
}

output "service_account_email" {
  value       = google_service_account.aiops.email
  description = "Service account email used by the AIOps assistant."
}

output "redis_host" {
  value       = local.redis_enabled ? google_redis_instance.session_memory[0].host : null
  description = "Memorystore host used for session memory."
}

output "openrouter_secret_name" {
  value       = google_secret_manager_secret.openrouter_api_key.secret_id
  description = "Secret Manager secret storing the OpenRouter API key."
}
