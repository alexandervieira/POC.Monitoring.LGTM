output "storage_account_name" {
  value = azurerm_storage_account.lgtm.name
}

output "storage_account_id" {
  value = azurerm_storage_account.lgtm.id
}

output "loki_container_name" {
  value = azurerm_storage_container.loki.name
}

output "tempo_container_name" {
  value = azurerm_storage_container.tempo.name
}

output "prometheus_container_name" {
  value = azurerm_storage_container.prometheus.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.lgtm.primary_blob_endpoint
}

output "primary_access_key" {
  value     = azurerm_storage_account.lgtm.primary_access_key
  sensitive = true
}
