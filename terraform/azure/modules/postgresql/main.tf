terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

resource "random_password" "admin" {
  length  = 24
  special = true
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-lgtm-${var.environment}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "15"
  delegated_subnet_id    = var.subnet_id
  private_dns_zone_id    = var.dns_zone_id
  administrator_login    = "pgadmin"
  administrator_password = random_password.admin.result
  zone                   = "1"
  storage_mb             = var.storage_mb
  sku_name               = var.sku_name
  backup_retention_days  = 7
  
  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "apicontagem" {
  name      = "BaseContagemPostgreSql"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_configuration" "retention" {
  name      = "pg_stat_statements.track"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "all"
}
