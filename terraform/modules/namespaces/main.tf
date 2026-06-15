resource "kubernetes_namespace_v1" "env_namespaces" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.value

    labels = {
      environment = var.environment
      owner       = var.owner
    }
  }
}
