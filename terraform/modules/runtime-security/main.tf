locals {
  enable_scc_notification = var.enable_scc_notification_config && var.organization_id != ""
}

data "archive_file" "security_alert_forwarder" {
  type        = "zip"
  source_dir  = "${path.root}/../../../cloud-functions/runtime-alert-forwarder"
  output_path = "${path.root}/../../../cloud-functions/runtime-alert-forwarder.zip"
}

resource "google_pubsub_topic" "falco_alerts" {
  name    = var.falco_alert_topic_name
  project = var.project_id
}

resource "google_pubsub_topic" "scc_findings" {
  name    = var.scc_findings_topic_name
  project = var.project_id
}

resource "google_bigquery_dataset" "audit_logs" {
  dataset_id  = var.audit_logs_dataset_id
  project     = var.project_id
  location    = var.region
  description = "PulseGuard exported audit logs for runtime security forensics."
}

resource "google_logging_project_sink" "audit_logs_to_bigquery" {
  name                   = var.audit_logs_sink_name
  project                = var.project_id
  destination            = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.audit_logs.dataset_id}"
  unique_writer_identity = true

  filter = <<-EOT
    logName:"cloudaudit.googleapis.com"
    AND (
      protoPayload.@type="type.googleapis.com/google.cloud.audit.AuditLog"
      OR protoPayload.methodName:* 
    )
  EOT

  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_bigquery_dataset_iam_member" "audit_logs_sink_writer" {
  dataset_id = google_bigquery_dataset.audit_logs.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.audit_logs_to_bigquery.writer_identity
}

resource "google_storage_bucket" "security_alert_source" {
  name                        = "${var.project_id}-${var.security_alert_bucket_name}"
  project                     = var.project_id
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "security_alert_source_zip" {
  name   = "runtime-alert-forwarder.zip"
  bucket = google_storage_bucket.security_alert_source.name
  source = data.archive_file.security_alert_forwarder.output_path
}

resource "google_cloudfunctions2_function" "security_alert_forwarder" {
  name        = var.security_alert_function_name
  location    = var.region
  project     = var.project_id
  description = "Consumes runtime security Pub/Sub events and emits structured Cloud Logging entries."

  build_config {
    runtime     = var.security_alert_function_runtime
    entry_point = var.security_alert_function_entry_point

    source {
      storage_source {
        bucket = google_storage_bucket.security_alert_source.name
        object = google_storage_bucket_object.security_alert_source_zip.name
      }
    }
  }

  service_config {
    available_memory   = "256M"
    timeout_seconds    = 60
    ingress_settings   = "ALLOW_INTERNAL_ONLY"
    max_instance_count = 2
    min_instance_count = 0
    environment_variables = {
      PROJECT_ID = var.project_id
    }
  }

  event_trigger {
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.falco_alerts.id
    retry_policy          = "RETRY_POLICY_RETRY"
    trigger_region        = var.region
    service_account_email = null
  }
}

resource "google_logging_metric" "runtime_security_alerts" {
  name        = var.security_alert_metric_name
  project     = var.project_id
  description = "Counts runtime security alerts forwarded by the Cloud Function."
  filter      = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.security_alert_function_name}\" AND jsonPayload.category=\"runtime-security\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "runtime_security_alerts" {
  project      = var.project_id
  display_name = var.security_alert_policy_display_name
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Runtime security event detected"

    condition_threshold {
      comparison      = "COMPARISON_GT"
      duration        = "0s"
      filter          = "metric.type=\"logging.googleapis.com/user/${var.security_alert_metric_name}\" resource.type=\"cloud_function\""
      threshold_value = 0

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  documentation {
    content   = "A runtime security event was forwarded from Falco into Cloud Logging."
    mime_type = "text/markdown"
  }
}

resource "google_logging_metric" "iam_drift" {
  name        = var.iam_drift_metric_name
  project     = var.project_id
  description = "Counts IAM binding changes detected in Cloud Audit Logs."
  filter      = "protoPayload.serviceName=\"cloudresourcemanager.googleapis.com\" AND protoPayload.methodName:(\"SetIamPolicy\" OR \"google.iam.admin.v1.CreateRole\" OR \"google.iam.admin.v1.UpdateRole\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "iam_drift" {
  project      = var.project_id
  display_name = var.iam_drift_alert_policy_display_name
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "IAM drift change detected"

    condition_threshold {
      comparison      = "COMPARISON_GT"
      duration        = "0s"
      filter          = "metric.type=\"logging.googleapis.com/user/${var.iam_drift_metric_name}\" resource.type=\"global\""
      threshold_value = 0

      aggregations {
        alignment_period   = "120s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  documentation {
    content   = "A manual IAM change or IAM role modification was detected outside the normal Terraform workflow."
    mime_type = "text/markdown"
  }
}

resource "google_scc_notification_config" "findings" {
  count = local.enable_scc_notification ? 1 : 0

  config_id    = var.scc_notification_config_id
  organization = var.organization_id
  pubsub_topic = google_pubsub_topic.scc_findings.id
  description  = "PulseGuard SCC HIGH and CRITICAL findings notification stream."

  streaming_config {
    filter = var.scc_notification_filter
  }
}

resource "helm_release" "falcosidekick" {
  count            = var.enable_falco ? 1 : 0
  name             = "falcosidekick"
  repository       = "https://falcosecurity.github.io/charts"
  chart            = "falcosidekick"
  version          = var.falco_sidekick_chart_version
  namespace        = var.observability_namespace
  create_namespace = false

  values = [
    templatefile("${path.module}/values/falcosidekick-values.yaml.tftpl", {
      falco_alert_topic = google_pubsub_topic.falco_alerts.name
      project_id        = var.project_id
    })
  ]
}

resource "helm_release" "falco" {
  count            = var.enable_falco ? 1 : 0
  name             = "falco"
  repository       = "https://falcosecurity.github.io/charts"
  chart            = "falco"
  version          = var.falco_chart_version
  namespace        = var.observability_namespace
  create_namespace = false

  values = [
    templatefile("${path.module}/values/falco-values.yaml.tftpl", {
      falco_sidekick_service = "falcosidekick"
    })
  ]

  depends_on = [helm_release.falcosidekick]
}
