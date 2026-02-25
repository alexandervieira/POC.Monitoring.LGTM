output "environment_id" {
  value = azurerm_container_app_environment.main.id
}

output "app_url" {
  value = "https://${azurerm_container_app.apicontagem.ingress[0].fqdn}"
}

output "app_fqdn" {
  value = azurerm_container_app.apicontagem.ingress[0].fqdn
}
