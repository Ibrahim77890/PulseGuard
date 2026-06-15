output "namespace" {
  value       = kubernetes_namespace_v1.observability.metadata[0].name
  description = "Namespace that hosts the observability stack."
}

output "grafana_service_name" {
  value       = "kube-prometheus-stack-grafana"
  description = "Grafana service created by kube-prometheus-stack."
}

output "prometheus_service_name" {
  value       = "kube-prometheus-stack-prometheus"
  description = "Prometheus service created by kube-prometheus-stack."
}

output "loki_service_name" {
  value       = "loki-gateway"
  description = "Loki gateway service created by the Loki chart."
}

output "tempo_service_name" {
  value       = "tempo"
  description = "Tempo service created by the Tempo chart."
}

output "promtail_release_name" {
  value       = "promtail"
  description = "Promtail release that ships pod logs into Loki."
}

output "otel_collector_service_name" {
  value       = "otel-collector"
  description = "OpenTelemetry Collector service created by the chart."
}
