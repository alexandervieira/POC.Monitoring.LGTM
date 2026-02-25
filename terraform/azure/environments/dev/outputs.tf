output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "aks_kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}

output "container_app_url" {
  value = module.container_apps.app_url
}

output "postgresql_fqdn" {
  value = module.postgresql.fqdn
}

output "grafana_endpoint" {
  value = module.monitoring.grafana_endpoint
}
