output "gsa_emails" {
  value       = { for k, v in google_service_account.namespace_gsa : k => v.email }
  description = "Map of namespace names to their GSA emails."
}

output "ksa_names" {
  value       = { for k, v in kubernetes_service_account_v1.namespace_ksa : k => v.metadata[0].name }
  description = "Map of namespace names to their KSA names."
}
