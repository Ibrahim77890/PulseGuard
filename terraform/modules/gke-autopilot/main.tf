resource "google_container_cluster" "autopilot" {
  name                  = var.cluster_name
  project               = var.project_id
  location              = var.region
  network               = var.network
  subnetwork            = var.subnetwork
  enable_autopilot      = true
  networking_mode       = "VPC_NATIVE"
  deletion_protection   = false
  enable_shielded_nodes = true
  resource_labels       = var.resource_labels

  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.enable_private_nodes ? var.master_ipv4_cidr_block : null
  }

  release_channel {
    channel = var.release_channel
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  timeouts {
    create = "30m"
    update = "40m"
  }
}
