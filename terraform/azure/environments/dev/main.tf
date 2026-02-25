terraform {
  required_version = ">= 1.6"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stlgtmtfstate"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.0.host
    client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
    client_key             = base64decode(module.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
  }
}

locals {
  environment = "dev"
  location    = var.location
  tags = {
    Environment = "dev"
    Project     = "LGTM-Stack"
    ManagedBy   = "Terraform"
    LGPD        = "Enabled"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-lgtm-${local.environment}"
  location = local.location
  tags     = local.tags
}

module "network" {
  source = "../../modules/network"
  
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

module "storage" {
  source = "../../modules/storage"
  
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

module "aks" {
  source = "../../modules/aks"
  
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.network.aks_subnet_id
  node_count          = 2
  vm_size             = "Standard_D2s_v3"
  tags                = local.tags
  
  depends_on = [module.network]
}

module "postgresql" {
  source = "../../modules/postgresql"
  
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.network.postgresql_subnet_id
  dns_zone_id         = module.network.postgresql_dns_zone_id
  sku_name            = "B_Standard_B1ms"
  storage_mb          = 32768
  tags                = local.tags
  
  depends_on = [module.network]
}

module "monitoring" {
  source = "../../modules/monitoring"
  
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  aks_cluster_id      = module.aks.cluster_id
  
  storage_account_name       = module.storage.storage_account_name
  storage_account_key        = module.storage.primary_access_key
  loki_container_name        = module.storage.loki_container_name
  tempo_container_name       = module.storage.tempo_container_name
  prometheus_container_name  = module.storage.prometheus_container_name
  
  tags = local.tags
  
  depends_on = [module.aks, module.storage]
}

module "container_apps" {
  source = "../../modules/container-apps"
  
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.network.container_apps_subnet_id
  otel_endpoint       = module.monitoring.otel_collector_endpoint
  db_connection_string = "Host=${module.postgresql.fqdn};Database=${module.postgresql.database_name};Username=${module.postgresql.admin_username};Password=${module.postgresql.admin_password}"
  tags                = local.tags
  
  depends_on = [module.network, module.postgresql, module.monitoring]
}
