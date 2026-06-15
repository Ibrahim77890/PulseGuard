locals {
  common_labels = {
    environment = var.environment
    owner       = var.owner
    project     = "pulseguard"
    phase       = "02"
  }

  grafana_dashboards = {
    red          = file("${path.root}/../../../grafana/dashboards/red-services.json")
    use          = file("${path.root}/../../../grafana/dashboards/use-cluster.json")
    error_budget = file("${path.root}/../../../grafana/dashboards/error-budget-overview.json")
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "current" {}

module "gcp_project" {
  source = "../../modules/gcp-project"

  project_id   = var.project_id
  gcp_api_list = var.gcp_api_list
}

module "gke_autopilot" {
  source = "../../modules/gke-autopilot"

  project_id                    = var.project_id
  cluster_name                  = var.cluster_name
  region                        = var.region
  network                       = var.network
  subnetwork                    = var.subnetwork
  cluster_secondary_range_name  = var.cluster_secondary_range_name
  services_secondary_range_name = var.services_secondary_range_name
  enable_private_nodes          = var.enable_private_nodes
  enable_private_endpoint       = var.enable_private_endpoint
  master_ipv4_cidr_block        = var.master_ipv4_cidr_block
  release_channel               = var.release_channel
  resource_labels               = local.common_labels

  depends_on = [module.gcp_project]
}

provider "kubernetes" {
  host                   = "https://${module.gke_autopilot.cluster_endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(module.gke_autopilot.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = "https://${module.gke_autopilot.cluster_endpoint}"
    token                  = data.google_client_config.current.access_token
    cluster_ca_certificate = base64decode(module.gke_autopilot.cluster_ca_certificate)
  }
}

module "namespaces" {
  source = "../../modules/namespaces"

  namespaces  = var.namespaces
  environment = var.environment
  owner       = var.owner

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [module.gke_autopilot]
}

module "workload_identity" {
  source = "../../modules/workload-identity"

  project_id  = var.project_id
  environment = var.environment
  namespaces  = var.namespaces
  ksa_suffix  = "app"

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [module.namespaces]
}

module "rbac" {
  source = "../../modules/rbac"

  namespaces = var.namespaces

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [module.namespaces]
}

module "network_policies" {
  source = "../../modules/network-policies"

  namespaces              = var.namespaces
  observability_namespace = var.observability_namespace

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [module.namespaces]
}

module "observability_stack" {
  source = "../../modules/observability-stack"

  environment                         = var.environment
  namespace                           = var.observability_namespace
  grafana_admin_password              = var.grafana_admin_password
  grafana_dashboards                  = local.grafana_dashboards
  grafana_storage_size                = var.grafana_storage_size
  prometheus_storage_size             = var.prometheus_storage_size
  loki_storage_size                   = var.loki_storage_size
  tempo_storage_size                  = var.tempo_storage_size
  promtail_chart_version              = var.promtail_chart_version
  kube_prometheus_stack_chart_version = var.kube_prometheus_stack_chart_version
  loki_chart_version                  = var.loki_chart_version
  tempo_chart_version                 = var.tempo_chart_version
  otel_collector_chart_version        = var.otel_collector_chart_version

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  depends_on = [module.gke_autopilot]
}

module "slo_engineering" {
  source = "../../modules/slo-engineering"

  project_id                    = var.project_id
  environment                   = var.environment
  slo_services                  = var.slo_services
  slo_window_days               = var.slo_window_days
  availability_goal             = var.availability_goal
  latency_goal                  = var.latency_goal
  latency_threshold_ms          = var.latency_threshold_ms
  enable_google_monitoring_slos = var.enable_google_monitoring_slos
  google_monitoring_service_ids = var.google_monitoring_service_ids
  uptime_check_urls             = var.uptime_check_urls
  uptime_check_path             = var.uptime_check_path

  depends_on = [module.observability_stack]
}
