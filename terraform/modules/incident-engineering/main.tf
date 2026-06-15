resource "kubernetes_namespace_v1" "chaos_mesh" {
  count = var.enable_chaos_mesh ? 1 : 0

  metadata {
    name = var.chaos_mesh_namespace

    labels = {
      environment = "dev"
      owner       = "platform"
      project     = "pulseguard"
      phase       = "06"
    }
  }
}

resource "helm_release" "chaos_mesh" {
  count            = var.enable_chaos_mesh ? 1 : 0
  name             = "chaos-mesh"
  repository       = "https://charts.chaos-mesh.org"
  chart            = "chaos-mesh"
  version          = var.chaos_mesh_chart_version
  namespace        = var.chaos_mesh_namespace
  create_namespace = false

  values = [
    templatefile("${path.module}/values/chaos-mesh-values.yaml.tftpl", {
      chaos_mesh_dashboard_enabled = var.chaos_mesh_dashboard_enabled
    })
  ]

  depends_on = [kubernetes_namespace_v1.chaos_mesh]
}
