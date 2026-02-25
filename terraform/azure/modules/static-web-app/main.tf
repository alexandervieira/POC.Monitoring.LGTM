terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

resource "azurerm_static_web_app" "frontend" {
  name                = "swa-lgtm-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_tier            = var.sku_tier
  sku_size            = var.sku_size
  
  tags = var.tags
}

resource "azurerm_static_web_app_custom_domain" "frontend" {
  count               = var.custom_domain != "" ? 1 : 0
  static_web_app_id   = azurerm_static_web_app.frontend.id
  domain_name         = var.custom_domain
  validation_type     = "cname-delegation"
}
