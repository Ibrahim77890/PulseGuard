locals {
  redis_enabled          = var.enable_redis_memory
  secret_version_enabled = var.openrouter_api_key_secret_value != ""
  memory_backend         = local.redis_enabled ? "redis" : "memory"
}

resource "google_service_account" "aiops" {
  account_id   = var.aiops_service_account_id
  display_name = "PulseGuard AIOps Assistant"
  project      = var.project_id
}

resource "google_project_iam_member" "monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.aiops.email}"
}

resource "google_project_iam_member" "logging_viewer" {
  project = var.project_id
  role    = "roles/logging.viewer"
  member  = "serviceAccount:${google_service_account.aiops.email}"
}

resource "google_secret_manager_secret" "openrouter_api_key" {
  secret_id = var.openrouter_api_key_secret_name
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "openrouter_api_key" {
  count = local.secret_version_enabled ? 1 : 0

  secret      = google_secret_manager_secret.openrouter_api_key.id
  secret_data = var.openrouter_api_key_secret_value
}

resource "google_secret_manager_secret_iam_member" "aiops_secret_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.openrouter_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.aiops.email}"
}

resource "google_vpc_access_connector" "aiops" {
  count = local.redis_enabled ? 1 : 0

  name          = var.aiops_vpc_connector_name
  project       = var.project_id
  region        = var.region
  ip_cidr_range = var.aiops_vpc_connector_cidr
  network       = var.network

  subnet {
    name = var.subnetwork
  }
}

resource "google_redis_instance" "session_memory" {
  count = local.redis_enabled ? 1 : 0

  name               = var.redis_instance_name
  project            = var.project_id
  region             = var.region
  tier               = "BASIC"
  memory_size_gb     = var.redis_memory_size_gb
  redis_version      = var.redis_version
  authorized_network = var.network
  connect_mode       = "DIRECT_PEERING"
  display_name       = "PulseGuard AIOps Session Memory"
}

resource "google_cloud_run_v2_service" "aiops" {
  name     = var.aiops_service_name
  project  = var.project_id
  location = var.region
  ingress  = var.aiops_ingress

  template {
    service_account = google_service_account.aiops.email
    timeout         = "${var.aiops_timeout_seconds}s"

    scaling {
      min_instance_count = var.aiops_min_instances
      max_instance_count = var.aiops_max_instances
    }

    dynamic "vpc_access" {
      for_each = local.redis_enabled ? [1] : []

      content {
        connector = google_vpc_access_connector.aiops[0].id
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }

    containers {
      image = var.aiops_service_image

      ports {
        container_port = 8080
      }

      env {
        name  = "SERVICE_NAME"
        value = var.aiops_service_name
      }

      env {
        name  = "OPENROUTER_BASE_URL"
        value = var.openrouter_base_url
      }

      env {
        name  = "OPENROUTER_DEFAULT_MODEL"
        value = var.openrouter_default_model
      }

      env {
        name  = "OPENROUTER_REASONING_MODEL"
        value = var.openrouter_reasoning_model
      }

      env {
        name  = "PROMETHEUS_BASE_URL"
        value = var.prometheus_base_url
      }

      env {
        name  = "LOKI_BASE_URL"
        value = var.loki_base_url
      }

      env {
        name  = "GRAFANA_BASE_URL"
        value = var.grafana_base_url
      }

      env {
        name  = "MEMORY_BACKEND"
        value = local.memory_backend
      }

      env {
        name  = "RUNBOOKS_ROOT"
        value = "/app/docs/runbooks"
      }

      env {
        name  = "POSTMORTEMS_ROOT"
        value = "/app/docs/postmortems"
      }

      dynamic "env" {
        for_each = local.redis_enabled ? [1] : []

        content {
          name  = "REDIS_HOST"
          value = google_redis_instance.session_memory[0].host
        }
      }

      dynamic "env" {
        for_each = local.redis_enabled ? [1] : []

        content {
          name  = "REDIS_PORT"
          value = tostring(google_redis_instance.session_memory[0].port)
        }
      }

      dynamic "env" {
        for_each = local.secret_version_enabled ? [1] : []

        content {
          name = "OPENROUTER_API_KEY"

          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.openrouter_api_key.secret_id
              version = "latest"
            }
          }
        }
      }

      dynamic "env" {
        for_each = local.secret_version_enabled ? [] : [1]

        content {
          name  = "OPENROUTER_API_KEY"
          value = ""
        }
      }

      resources {
        limits = {
          cpu    = var.aiops_cpu
          memory = var.aiops_memory
        }
      }
    }
  }

  depends_on = [
    google_project_iam_member.monitoring_viewer,
    google_project_iam_member.logging_viewer,
    google_secret_manager_secret_iam_member.aiops_secret_accessor,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.allow_unauthenticated ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.aiops.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
