resource "google_service_account" "namespace_gsa" {
  for_each = toset(var.namespaces)

  account_id   = "pg-${var.environment}-${each.value}"
  display_name = "PulseGuard ${var.environment} ${each.value} workload identity"
  project      = var.project_id
}

resource "kubernetes_service_account" "namespace_ksa" {
  for_each = toset(var.namespaces)

  metadata {
    name      = "${each.value}-${var.ksa_suffix}"
    namespace = each.value

    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.namespace_gsa[each.value].email
    }

    labels = {
      app         = each.value
      environment = var.environment
      managed-by  = "terraform"
    }
  }

  automount_service_account_token = true
}

resource "google_service_account_iam_binding" "workload_identity_binding" {
  for_each = toset(var.namespaces)

  service_account_id = google_service_account.namespace_gsa[each.value].name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${each.value}/${each.value}-${var.ksa_suffix}]"
  ]
}
