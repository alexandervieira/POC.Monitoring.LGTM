terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

# Storage Account para LGTM Stack
resource "azurerm_storage_account" "lgtm" {
  name                     = "stlgtm${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  account_kind             = "StorageV2"
  
  blob_properties {
    delete_retention_policy {
      days = 90
    }
    container_delete_retention_policy {
      days = 90
    }
  }
  
  tags = var.tags
}

# Container para Loki (logs)
resource "azurerm_storage_container" "loki" {
  name                  = "loki-logs"
  storage_account_name  = azurerm_storage_account.lgtm.name
  container_access_type = "private"
}

# Container para Tempo (traces)
resource "azurerm_storage_container" "tempo" {
  name                  = "tempo-traces"
  storage_account_name  = azurerm_storage_account.lgtm.name
  container_access_type = "private"
}

# Container para Prometheus (metrics)
resource "azurerm_storage_container" "prometheus" {
  name                  = "prometheus-metrics"
  storage_account_name  = azurerm_storage_account.lgtm.name
  container_access_type = "private"
}

# Lifecycle Management (LGPD - 90 dias)
resource "azurerm_storage_management_policy" "lgtm" {
  storage_account_id = azurerm_storage_account.lgtm.id

  rule {
    name    = "loki-retention"
    enabled = true
    filters {
      prefix_match = ["loki-logs/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 90
      }
    }
  }

  rule {
    name    = "tempo-retention"
    enabled = true
    filters {
      prefix_match = ["tempo-traces/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 90
      }
    }
  }

  rule {
    name    = "prometheus-retention"
    enabled = true
    filters {
      prefix_match = ["prometheus-metrics/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 90
      }
    }
  }
}
