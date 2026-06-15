resource "kubernetes_cluster_role_v1" "viewer" {
  metadata {
    name = "pulseguard-viewer"
  }

  rule {
    api_groups = ["", "apps", "batch", "autoscaling", "networking.k8s.io"]
    resources = [
      "pods",
      "pods/log",
      "services",
      "endpoints",
      "configmaps",
      "events",
      "deployments",
      "replicasets",
      "statefulsets",
      "daemonsets",
      "jobs",
      "cronjobs",
      "horizontalpodautoscalers",
      "networkpolicies"
    ]
    verbs = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_v1" "deployer" {
  metadata {
    name = "pulseguard-deployer"
  }

  rule {
    api_groups = ["", "apps", "batch", "autoscaling", "networking.k8s.io"]
    resources = [
      "pods",
      "services",
      "configmaps",
      "deployments",
      "replicasets",
      "statefulsets",
      "daemonsets",
      "jobs",
      "cronjobs",
      "horizontalpodautoscalers",
      "ingresses"
    ]
    verbs = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_cluster_role_v1" "namespace_admin" {
  metadata {
    name = "pulseguard-namespace-admin"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_service_account_v1" "viewer" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "viewer"
    namespace = each.value
  }
}

resource "kubernetes_service_account_v1" "deployer" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "ci-deployer"
    namespace = each.value
  }
}

resource "kubernetes_service_account_v1" "namespace_admin" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "namespace-admin"
    namespace = each.value
  }
}

resource "kubernetes_role_binding_v1" "viewer" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "viewer-binding"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.viewer.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.viewer[each.value].metadata[0].name
    namespace = each.value
  }
}

resource "kubernetes_role_binding_v1" "deployer" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "deployer-binding"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.deployer.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.deployer[each.value].metadata[0].name
    namespace = each.value
  }
}

resource "kubernetes_role_binding_v1" "namespace_admin" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "namespace-admin-binding"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.namespace_admin.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.namespace_admin[each.value].metadata[0].name
    namespace = each.value
  }
}
