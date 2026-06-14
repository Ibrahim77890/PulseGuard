locals {
  common_labels = {
    environment = var.environment
    owner       = var.owner
    project     = "pulseguard"
    phase       = "01"
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

  namespaces = var.namespaces

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [module.namespaces]
}
