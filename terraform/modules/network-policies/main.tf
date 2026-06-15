resource "kubernetes_network_policy_v1" "default_deny" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "default-deny-all"
    namespace = each.value
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy_v1" "allow_dns" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "allow-dns-egress"
    namespace = each.value
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }

      ports {
        protocol = "UDP"
        port     = 53
      }

      ports {
        protocol = "TCP"
        port     = 53
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "allow_mesh_control_plane" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "allow-istio-control-plane-egress"
    namespace = each.value
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "istio-system"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = 443
      }

      ports {
        protocol = "TCP"
        port     = 15012
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "allow_egress_to_observability" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "allow-egress-to-observability"
    namespace = each.value
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = var.observability_namespace
          }
        }
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "allow_ingress_from_observability" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "allow-ingress-from-observability"
    namespace = each.value
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = var.observability_namespace
          }
        }
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "frontend_egress_to_backend" {
  metadata {
    name      = "allow-egress-to-backend"
    namespace = "frontend"
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "backend"
          }
        }
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "backend_ingress_from_frontend" {
  metadata {
    name      = "allow-ingress-from-frontend"
    namespace = "backend"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "frontend"
          }
        }
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "backend_egress_to_data" {
  metadata {
    name      = "allow-egress-to-data"
    namespace = "backend"
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "data"
          }
        }
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "data_ingress_from_backend" {
  metadata {
    name      = "allow-ingress-from-backend"
    namespace = "data"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "backend"
          }
        }
      }
    }
  }
}
