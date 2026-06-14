output "namespace_names" {
  value       = [for ns in kubernetes_namespace.env_namespaces : ns.metadata[0].name]
  description = "List of created namespace names."
}