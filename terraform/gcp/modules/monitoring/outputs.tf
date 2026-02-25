output "otel_collector_endpoint" {
  value = "http://otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317"
}

output "grafana_service" {
  value = "grafana.monitoring.svc.cluster.local"
}

output "loki_endpoint" {
  value = "http://loki-gateway.monitoring.svc.cluster.local"
}

output "tempo_endpoint" {
  value = "http://tempo.monitoring.svc.cluster.local:3100"
}

output "prometheus_endpoint" {
  value = "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090"
}
