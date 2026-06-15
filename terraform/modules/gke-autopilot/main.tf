resource "google_container_cluster" "autopilot" {
  name                = var.cluster_name
  project             = var.project_id
  location            = var.region
  network             = var.network
  subnetwork          = var.subnetwork
  enable_autopilot    = true
  networking_mode     = "VPC_NATIVE"
  deletion_protection = false
  resource_labels     = var.resource_labels

  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.enable_private_nodes ? var.master_ipv4_cidr_block : null
  }

  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []

    content {
      evaluation_mode = var.binary_authorization_evaluation_mode
    }
  }

  dynamic "security_posture_config" {
    for_each = var.enable_security_posture ? [1] : []

    content {
      mode               = var.security_posture_mode
      vulnerability_mode = var.security_posture_vulnerability_mode
    }
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
