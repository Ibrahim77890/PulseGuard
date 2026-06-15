locals {
  enable_billing_budget = var.enable_billing_budget && var.billing_account_id != ""
}

resource "google_bigquery_dataset" "billing_export" {
  count = var.create_billing_export_dataset ? 1 : 0

  dataset_id  = var.billing_export_dataset_id
  project     = var.project_id
  location    = var.region
  description = "PulseGuard billing export dataset for cost observability and FinOps analysis."
}

resource "google_billing_budget" "project_budget" {
  count = local.enable_billing_budget ? 1 : 0

  billing_account = var.billing_account_id
  display_name    = var.billing_budget_display_name

  amount {
    specified_amount {
      currency_code = var.billing_budget_currency
      units         = tostring(var.billing_budget_amount_units)
    }
  }

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  dynamic "threshold_rules" {
    for_each = var.billing_budget_threshold_percents

    content {
      threshold_percent = threshold_rules.value
    }
  }
}

resource "helm_release" "gatekeeper" {
  count            = var.enable_gatekeeper ? 1 : 0
  name             = "gatekeeper"
  repository       = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart            = "gatekeeper"
  version          = var.gatekeeper_chart_version
  namespace        = var.gatekeeper_namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values/gatekeeper-values.yaml.tftpl", {
      observability_namespace = var.observability_namespace
    })
  ]
}

resource "helm_release" "opencost" {
  count            = var.enable_opencost ? 1 : 0
  name             = "opencost"
  repository       = "https://opencost.github.io/opencost-helm-chart"
  chart            = "opencost"
  version          = var.opencost_chart_version
  namespace        = var.observability_namespace
  create_namespace = false

  values = [
    templatefile("${path.module}/values/opencost-values.yaml.tftpl", {
      cluster_name            = var.cluster_name
      observability_namespace = var.observability_namespace
    })
  ]
}
