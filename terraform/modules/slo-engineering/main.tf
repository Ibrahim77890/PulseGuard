locals {
  services = toset(var.slo_services)

  google_monitoring_services = var.enable_google_monitoring_slos ? {
    for service in var.slo_services : service => {
      service_id = lookup(var.google_monitoring_service_ids, service, "")
      url        = lookup(var.uptime_check_urls, service, "")
    }
    if lookup(var.google_monitoring_service_ids, service, "") != "" && lookup(var.uptime_check_urls, service, "") != ""
  } : {}
}

resource "google_monitoring_uptime_check_config" "service" {
  for_each = local.google_monitoring_services

  display_name = "pulseguard-${var.environment}-${each.key}-uptime"
  timeout      = "10s"
  period       = "60s"

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = trimsuffix(trimprefix(trimprefix(each.value.url, "https://"), "http://"), "/")
    }
  }

  http_check {
    path           = var.uptime_check_path
    port           = startswith(each.value.url, "https://") ? 443 : 80
    use_ssl        = startswith(each.value.url, "https://")
    validate_ssl   = startswith(each.value.url, "https://")
    request_method = "GET"
  }

  selected_regions = ["USA"]
}

resource "google_monitoring_slo" "availability" {
  for_each = local.google_monitoring_services

  service             = startswith(each.value.service_id, "projects/") ? each.value.service_id : "projects/${var.project_id}/services/${each.value.service_id}"
  slo_id              = "availability-${each.key}"
  display_name        = "PulseGuard ${each.key} availability SLO"
  goal                = var.availability_goal
  rolling_period_days = var.slo_window_days

  basic_sli {
    availability {}
  }
}

resource "google_monitoring_slo" "latency" {
  for_each = local.google_monitoring_services

  service             = startswith(each.value.service_id, "projects/") ? each.value.service_id : "projects/${var.project_id}/services/${each.value.service_id}"
  slo_id              = "latency-${each.key}"
  display_name        = "PulseGuard ${each.key} latency SLO"
  goal                = var.latency_goal
  rolling_period_days = var.slo_window_days

  request_based_sli {
    distribution_cut {
      distribution_filter = "metric.type=\"custom.googleapis.com/opencensus/http/server/latency\" resource.type=\"k8s_container\" metric.label.\"service\"=\"${each.key}\""
      range {
        max = var.latency_threshold_ms / 1000
      }
    }
  }
}
