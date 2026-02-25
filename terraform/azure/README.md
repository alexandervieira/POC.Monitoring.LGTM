# Terraform Azure - Stack LGTM + LGPD

## Estrutura de Diretórios

```
terraform/azure/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── modules/
    ├── aks/
    │   ├── main.tf
    │   └── variables.tf
    ├── container-apps/
    │   ├── main.tf
    │   └── variables.tf
    ├── postgresql/
    │   ├── main.tf
    │   └── variables.tf
    └── monitoring/
        ├── main.tf
        └── variables.tf
```

## Deploy por Ambiente

### Dev
```bash
cd terraform/azure/environments/dev
terraform init
terraform plan
terraform apply
```

### Staging
```bash
cd terraform/azure/environments/staging
terraform init
terraform plan -var="node_count=3"
terraform apply
```

### Prod
```bash
cd terraform/azure/environments/prod
terraform init
terraform plan -var="node_count=5" -var="vm_size=Standard_D4s_v3"
terraform apply
```

## Módulos Pendentes

Crie os seguintes arquivos para completar a infraestrutura:

### modules/container-apps/main.tf
```hcl
resource "azurerm_container_app_environment" "main" {
  name                = "cae-lgtm-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_container_app" "api" {
  name                         = "ca-apicontagem-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "apicontagem"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      
      env {
        name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
        value = "http://otel-collector:4317"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}

output "app_url" {
  value = azurerm_container_app.api.latest_revision_fqdn
}
```

### modules/postgresql/main.tf
```hcl
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-lgtm-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  sku_name   = var.sku_name
  storage_mb = var.storage_mb
  version    = "14"
  
  administrator_login    = "psqladmin"
  administrator_password = var.admin_password
  
  backup_retention_days = 7
  geo_redundant_backup_enabled = false
  
  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "basecontagem" {
  name      = "basecontagem"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

output "fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}
```

### modules/monitoring/main.tf
```hcl
resource "azurerm_dashboard_grafana" "main" {
  name                = "grafana-lgtm-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  identity {
    type = "SystemAssigned"
  }
  
  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.main.id
  }
  
  tags = var.tags
}

resource "azurerm_monitor_workspace" "main" {
  name                = "amw-lgtm-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

output "grafana_endpoint" {
  value = azurerm_dashboard_grafana.main.endpoint
}
```

## Variáveis por Ambiente

### Dev (menor custo)
- AKS: 2 nodes Standard_D2s_v3
- PostgreSQL: B_Standard_B1ms
- Container Apps: 0.25 CPU, 0.5Gi RAM

### Staging (médio)
- AKS: 3 nodes Standard_D2s_v3
- PostgreSQL: GP_Standard_D2s_v3
- Container Apps: 0.5 CPU, 1Gi RAM

### Prod (alta disponibilidade)
- AKS: 5 nodes Standard_D4s_v3
- PostgreSQL: GP_Standard_D4s_v3 (HA)
- Container Apps: 1 CPU, 2Gi RAM

## Custos Estimados

| Ambiente | AKS | PostgreSQL | Container Apps | Grafana | Total/mês |
|----------|-----|------------|----------------|---------|-----------|
| Dev | $140 | $30 | $20 | $100 | $290 |
| Staging | $210 | $150 | $40 | $100 | $500 |
| Prod | $700 | $400 | $80 | $100 | $1,280 |

## Comandos Úteis

```bash
# Validar configuração
terraform validate

# Formatar código
terraform fmt -recursive

# Ver plano sem aplicar
terraform plan -out=tfplan

# Aplicar plano salvo
terraform apply tfplan

# Destruir ambiente
terraform destroy

# Ver estado atual
terraform show

# Listar recursos
terraform state list
```
