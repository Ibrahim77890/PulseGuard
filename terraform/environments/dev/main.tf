locals {
  common_labels = {
    environment = var.environment
    owner       = var.owner
    project     = "pulseguard"
    phase       = "10"
  }

  grafana_dashboards = {
    llm_agent         = file("${path.root}/../../../grafana/dashboards/llm-agent-observability.json")
    red               = file("${path.root}/../../../grafana/dashboards/red-services.json")
    use               = file("${path.root}/../../../grafana/dashboards/use-cluster.json")
    cost_overview     = file("${path.root}/../../../grafana/dashboards/cost-overview.json")
    error_budget      = file("${path.root}/../../../grafana/dashboards/error-budget-overview.json")
    security_overview = file("${path.root}/../../../grafana/dashboards/security-operations-overview.json")
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

  project_id                           = var.project_id
  cluster_name                         = var.cluster_name
  region                               = var.region
  network                              = var.network
  subnetwork                           = var.subnetwork
  cluster_secondary_range_name         = var.cluster_secondary_range_name
  services_secondary_range_name        = var.services_secondary_range_name
  enable_private_nodes                 = var.enable_private_nodes
  enable_private_endpoint              = var.enable_private_endpoint
  master_ipv4_cidr_block               = var.master_ipv4_cidr_block
  release_channel                      = var.release_channel
  enable_binary_authorization          = var.enable_binary_authorization
  binary_authorization_evaluation_mode = var.binary_authorization_evaluation_mode
  enable_security_posture              = var.enable_security_posture
  security_posture_mode                = var.security_posture_mode
  security_posture_vulnerability_mode  = var.security_posture_vulnerability_mode
  resource_labels                      = local.common_labels

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

module "security_pipeline" {
  source = "../../modules/security-pipeline"

  project_id                                   = var.project_id
  region                                       = var.region
  artifact_registry_repository_id              = var.artifact_registry_repository_id
  artifact_registry_repository_description     = var.artifact_registry_repository_description
  create_artifact_registry_repository          = var.create_artifact_registry_repository
  enable_binary_authorization                  = var.enable_binary_authorization
  binary_authorization_policy_description      = var.binary_authorization_policy_description
  binary_authorization_enforcement_mode        = var.binary_authorization_enforcement_mode
  binary_authorization_default_evaluation_mode = var.binary_authorization_default_evaluation_mode
  attestor_name                                = var.attestor_name
  attestor_note_name                           = var.attestor_note_name
  attestor_note_hint                           = var.attestor_note_hint
  attestor_public_keys                         = var.attestor_public_keys

  depends_on = [module.gcp_project]
}

module "runtime_security" {
  source = "../../modules/runtime-security"

  project_id                          = var.project_id
  region                              = var.region
  observability_namespace             = var.observability_namespace
  enable_falco                        = var.enable_falco
  falco_chart_version                 = var.falco_chart_version
  falco_sidekick_chart_version        = var.falco_sidekick_chart_version
  falco_alert_topic_name              = var.falco_alert_topic_name
  scc_findings_topic_name             = var.scc_findings_topic_name
  security_alert_bucket_name          = var.security_alert_bucket_name
  security_alert_function_name        = var.security_alert_function_name
  security_alert_function_runtime     = var.security_alert_function_runtime
  security_alert_function_entry_point = var.security_alert_function_entry_point
  security_alert_metric_name          = var.security_alert_metric_name
  security_alert_policy_display_name  = var.security_alert_policy_display_name
  iam_drift_metric_name               = var.iam_drift_metric_name
  iam_drift_alert_policy_display_name = var.iam_drift_alert_policy_display_name
  audit_logs_dataset_id               = var.audit_logs_dataset_id
  audit_logs_sink_name                = var.audit_logs_sink_name
  enable_scc_notification_config      = var.enable_scc_notification_config
  organization_id                     = var.organization_id
  scc_notification_config_id          = var.scc_notification_config_id
  scc_notification_filter             = var.scc_notification_filter

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  depends_on = [module.observability_stack, module.gcp_project]
}

module "incident_engineering" {
  source = "../../modules/incident-engineering"

  observability_namespace      = var.observability_namespace
  chaos_mesh_namespace         = var.chaos_mesh_namespace
  enable_chaos_mesh            = var.enable_chaos_mesh
  chaos_mesh_chart_version     = var.chaos_mesh_chart_version
  chaos_mesh_dashboard_enabled = var.chaos_mesh_dashboard_enabled

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.observability_stack]
}

module "compliance_cost_observability" {
  source = "../../modules/compliance-cost-observability"

  project_id                        = var.project_id
  region                            = var.region
  cluster_name                      = var.cluster_name
  observability_namespace           = var.observability_namespace
  enable_gatekeeper                 = var.enable_gatekeeper
  gatekeeper_namespace              = var.gatekeeper_namespace
  gatekeeper_chart_version          = var.gatekeeper_chart_version
  enable_opencost                   = var.enable_opencost
  opencost_chart_version            = var.opencost_chart_version
  create_billing_export_dataset     = var.create_billing_export_dataset
  billing_export_dataset_id         = var.billing_export_dataset_id
  enable_billing_budget             = var.enable_billing_budget
  billing_account_id                = var.billing_account_id
  billing_budget_display_name       = var.billing_budget_display_name
  billing_budget_currency           = var.billing_budget_currency
  billing_budget_amount_units       = var.billing_budget_amount_units
  billing_budget_threshold_percents = var.billing_budget_threshold_percents

  providers = {
    helm = helm
  }

  depends_on = [module.observability_stack, module.gcp_project]
}

module "aiops_assistant" {
  source = "../../modules/aiops-assistant"

  project_id                      = var.project_id
  region                          = var.region
  network                         = var.network
  subnetwork                      = var.subnetwork
  aiops_service_name              = var.aiops_service_name
  aiops_service_image             = var.aiops_service_image
  aiops_service_account_id        = var.aiops_service_account_id
  aiops_ingress                   = var.aiops_ingress
  aiops_timeout_seconds           = var.aiops_timeout_seconds
  aiops_min_instances             = var.aiops_min_instances
  aiops_max_instances             = var.aiops_max_instances
  aiops_cpu                       = var.aiops_cpu
  aiops_memory                    = var.aiops_memory
  allow_unauthenticated           = var.aiops_allow_unauthenticated
  openrouter_api_key_secret_name  = var.openrouter_api_key_secret_name
  openrouter_api_key_secret_value = var.openrouter_api_key_secret_value
  openrouter_base_url             = var.openrouter_base_url
  openrouter_default_model        = var.openrouter_default_model
  openrouter_reasoning_model      = var.openrouter_reasoning_model
  prometheus_base_url             = var.aiops_prometheus_base_url
  loki_base_url                   = var.aiops_loki_base_url
  grafana_base_url                = var.aiops_grafana_base_url
  otel_exporter_otlp_endpoint     = var.aiops_otel_exporter_otlp_endpoint
  allowed_outbound_hosts          = var.aiops_allowed_outbound_hosts
  enable_prompt_guardrails        = var.aiops_enable_prompt_guardrails
  ai_security_audit_logging       = var.aiops_security_audit_logging
  eval_results_path               = var.aiops_eval_results_path
  model_pricing_usd_per_million   = var.aiops_model_pricing_usd_per_million
  enable_redis_memory             = var.aiops_enable_redis_memory
  redis_instance_name             = var.aiops_redis_instance_name
  redis_memory_size_gb            = var.aiops_redis_memory_size_gb
  redis_version                   = var.aiops_redis_version
  aiops_vpc_connector_name        = var.aiops_vpc_connector_name
  aiops_vpc_connector_cidr        = var.aiops_vpc_connector_cidr

  depends_on = [module.observability_stack, module.gcp_project]
}
