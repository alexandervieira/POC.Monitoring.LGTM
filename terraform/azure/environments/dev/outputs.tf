output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_name" {
  value = module.network.vnet_name
}

output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "aks_kube_config" {
  value     = module.aks.kube_config_raw
  sensitive = true
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "postgresql_fqdn" {
  value = module.postgresql.fqdn
}

output "postgresql_admin_username" {
  value = module.postgresql.admin_username
}

output "postgresql_admin_password" {
  value     = module.postgresql.admin_password
  sensitive = true
}

output "container_app_url" {
  value = module.container_apps.app_url
}

output "otel_collector_endpoint" {
  value       = module.monitoring.otel_collector_endpoint
  description = "OpenTelemetry Collector endpoint com sanitização LGPD"
}

output "grafana_url" {
  value = module.monitoring.grafana_url
}

output "loki_endpoint" {
  value = module.monitoring.loki_endpoint
}

output "tempo_endpoint" {
  value = module.monitoring.tempo_endpoint
}

output "prometheus_endpoint" {
  value = module.monitoring.prometheus_endpoint
}

output "frontend_url" {
  value       = module.static_web_app.url
  description = "Azure Static Web App URL"
}

output "frontend_api_key" {
  value     = module.static_web_app.api_key
  sensitive = true
}
