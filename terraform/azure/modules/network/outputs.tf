output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

output "container_apps_subnet_id" {
  value = azurerm_subnet.container_apps.id
}

output "postgresql_subnet_id" {
  value = azurerm_subnet.postgresql.id
}

output "postgresql_dns_zone_id" {
  value = azurerm_private_dns_zone.postgresql.id
}
