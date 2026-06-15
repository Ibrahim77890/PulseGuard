output "chaos_mesh_namespace" {
  value       = var.enable_chaos_mesh ? kubernetes_namespace_v1.chaos_mesh[0].metadata[0].name : null
  description = "Namespace hosting Chaos Mesh."
}
