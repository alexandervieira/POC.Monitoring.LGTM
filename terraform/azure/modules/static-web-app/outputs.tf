output "static_web_app_id" {
  value = azurerm_static_web_app.frontend.id
}

output "default_host_name" {
  value = azurerm_static_web_app.frontend.default_host_name
}

output "url" {
  value = "https://${azurerm_static_web_app.frontend.default_host_name}"
}

output "api_key" {
  value     = azurerm_static_web_app.frontend.api_key
  sensitive = true
}
