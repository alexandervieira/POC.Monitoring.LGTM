# Módulo Terraform - Cloud Run

Módulo para deploy de serviços no Google Cloud Run com configurações avançadas para APIs .NET.

## Características

- ✅ Suporte a múltiplos ambientes (dev/stage/prod)
- ✅ Integração com VPC Serverless Connector
- ✅ Conexão com Cloud SQL (PostgreSQL)
- ✅ Health checks configuráveis (startup + liveness)
- ✅ Scale to zero (min_instances = 0)
- ✅ Secrets do Secret Manager
- ✅ Domínios customizados
- ✅ Keep-warm para reduzir cold starts
- ✅ Métricas e SLOs
- ✅ Traffic splitting para canary deployments
- ✅ Session affinity

## Uso Básico

```hcl
module "cloud_run_api" {
  source = "../../modules/cloud-run"
  
  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  service_name = "apicontagem-${var.environment}"
  
  # Container
  image = "us-central1-docker.pkg.dev/${var.project_id}/backend/apicontagem:latest"
  
  # Recursos
  cpu           = "1"
  memory        = "512Mi"
  min_instances = 0
  max_instances = 10
  
  # Health checks
  health_check_config = {
    enabled               = true
    http_get_path         = "/health"
    initial_delay_seconds = 10
    period_seconds        = 30
    failure_threshold     = 3
  }
  
  # Variáveis de ambiente
  env_vars = {
    ASPNETCORE_ENVIRONMENT = title(var.environment)
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://alloy.monitoring.svc.cluster.local:4317"
  }
  
  # Secrets
  secrets = {
    DB_PASSWORD = {
      secret_id = "db-password-${var.environment}"
      version   = "latest"
    }
  }
  
  # Cloud SQL
  cloud_sql_connections = [module.cloud_sql.instance_connection_name]
  
  # VPC Connector
  vpc_connector_enabled = true
  vpc_connector_name    = module.networking.vpc_connector_name
  
  # Acesso público
  public_access = var.environment != "prod" ? true : false
  invoker_members = ["allUsers"]
}