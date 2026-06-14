output "enabled_api_services" {
  value       = [for api in google_project_service.enabled_apis : api.service]
  description = "List of APIs that have been enabled by this module."
}

output "project_api_dependency" {
  value       = google_project_service.enabled_apis
  description = "An internal output used to force other modules to wait for API activation."
}