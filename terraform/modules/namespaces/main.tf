resource "kubernetes_namespace" "env_namespaces" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.value

    labels = {
      environment = var.environment
      owner       = var.owner
    }
  }
}