terraform {
  required_version = ">= 1.6"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
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

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-lgtm-${local.environment}"
  location = local.location
  tags     = local.tags
}

# AKS Module
module "aks" {
  source = "../../modules/aks"
  
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  node_count          = 2
  vm_size             = "Standard_D2s_v3"
  tags                = local.tags
}

# Container Apps Module
module "container_apps" {
  source = "../../modules/container-apps"
  
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

# PostgreSQL Module
module "postgresql" {
  source = "../../modules/postgresql"
  
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "B_Standard_B1ms"
  storage_mb          = 32768
  tags                = local.tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"
  
  environment         = local.environment
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}
