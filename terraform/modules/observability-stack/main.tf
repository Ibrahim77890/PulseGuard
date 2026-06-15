resource "kubernetes_namespace_v1" "observability" {
  metadata {
    name = var.namespace

    labels = {
      environment = var.environment
      owner       = "platform"
      project     = "pulseguard"
      phase       = "02"
      tier        = "platform"
    }
  }
}

resource "kubernetes_config_map_v1" "grafana_dashboards" {
  for_each = var.grafana_dashboards

  metadata {
    name      = "grafana-dashboard-${each.key}"
    namespace = kubernetes_namespace_v1.observability.metadata[0].name
    labels = {
      grafana_dashboard = "1"
      app               = "grafana"
    }
  }

  data = {
    "${each.key}.json" = each.value
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.kube_prometheus_stack_chart_version
  namespace        = kubernetes_namespace_v1.observability.metadata[0].name
  create_namespace = false

  values = [
    templatefile("${path.module}/values/kube-prometheus-stack-values.yaml.tftpl", {
      grafana_admin_password  = var.grafana_admin_password
      grafana_storage_size    = var.grafana_storage_size
      prometheus_storage_size = var.prometheus_storage_size
      namespace               = var.namespace
    })
  ]

  depends_on = [kubernetes_namespace_v1.observability, kubernetes_config_map_v1.grafana_dashboards]
}

resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  version          = var.loki_chart_version
  namespace        = kubernetes_namespace_v1.observability.metadata[0].name
  create_namespace = false

  values = [
    templatefile("${path.module}/values/loki-values.yaml.tftpl", {
      loki_storage_size = var.loki_storage_size
      namespace         = var.namespace
    })
  ]

  depends_on = [kubernetes_namespace_v1.observability]
}

resource "helm_release" "tempo" {
  name             = "tempo"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "tempo"
  version          = var.tempo_chart_version
  namespace        = kubernetes_namespace_v1.observability.metadata[0].name
  create_namespace = false

  values = [
    templatefile("${path.module}/values/tempo-values.yaml.tftpl", {
      tempo_storage_size = var.tempo_storage_size
      namespace          = var.namespace
    })
  ]

  depends_on = [kubernetes_namespace_v1.observability]
}

resource "helm_release" "promtail" {
  name             = "promtail"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "promtail"
  version          = var.promtail_chart_version
  namespace        = kubernetes_namespace_v1.observability.metadata[0].name
  create_namespace = false

  values = [
    templatefile("${path.module}/values/promtail-values.yaml.tftpl", {
      namespace = var.namespace
    })
  ]

  depends_on = [kubernetes_namespace_v1.observability, helm_release.loki]
}

resource "helm_release" "otel_collector" {
  name             = "otel-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  version          = var.otel_collector_chart_version
  namespace        = kubernetes_namespace_v1.observability.metadata[0].name
  create_namespace = false

  values = [
    templatefile("${path.module}/values/otel-collector-values.yaml.tftpl", {
      namespace = var.namespace
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.observability,
    helm_release.kube_prometheus_stack,
    helm_release.loki,
    helm_release.tempo,
    helm_release.promtail
  ]
}
