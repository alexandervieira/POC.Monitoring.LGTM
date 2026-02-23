# Outputs principais
output "service_name" {
  description = "Nome do serviço Cloud Run"
  value       = google_cloud_run_v2_service.main.name
}

output "service_id" {
  description = "ID completo do serviço"
  value       = google_cloud_run_v2_service.main.id
}

output "service_uri" {
  description = "URL do serviço"
  value       = google_cloud_run_v2_service.main.uri
}

output "service_location" {
  description = "Localização do serviço"
  value       = google_cloud_run_v2_service.main.location
}

output "latest_revision" {
  description = "Nome da última revisão"
  value       = google_cloud_run_v2_service.main.latest_ready_revision
}

output "observed_generation" {
  description = "Geração observada"
  value       = google_cloud_run_v2_service.main.observed_generation
}

# Outputs de condição
output "condition_ready" {
  description = "Status de ready do serviço"
  value       = google_cloud_run_v2_service.main.conditions[0].state
}

output "condition_message" {
  description = "Mensagem da condição"
  value       = google_cloud_run_v2_service.main.conditions[0].message
}

# Outputs de IAM
output "invoker_binding_id" {
  description = "ID do binding IAM público"
  value       = try(google_cloud_run_v2_service_iam_binding.public_invoker[0].id, null)
}

output "invoker_members" {
  description = "Membros com permissão de invocar"
  value       = var.invoker_members
}

# Outputs de domínio
output "custom_domain" {
  description = "Domínio customizado (se configurado)"
  value       = try(google_cloud_run_v2_service_domain_mapping.custom_domain[0].name, null)
}

output "custom_domain_status" {
  description = "Status do domínio customizado"
  value       = try(google_cloud_run_v2_service_domain_mapping.custom_domain[0].conditions[0].state, null)
}

# Outputs de keep-warm
output "keep_warm_job_name" {
  description = "Nome do job keep-warm"
  value       = try(google_cloud_scheduler_job.keep_warm[0].name, null)
}

output "keep_warm_sa_email" {
  description = "Email da service account keep-warm"
  value       = var.keep_warm_sa_email != null ? var.keep_warm_sa_email : try(google_service_account.keep_warm[0].email, null)
}

# Outputs de métricas
output "request_count_metric_name" {
  description = "Nome da métrica de contagem de requisições"
  value       = try(google_logging_metric.request_count[0].name, null)
}

output "availability_slo_name" {
  description = "Nome do SLO de disponibilidade"
  value       = try(google_monitoring_slo.availability[0].name, null)
}

output "latency_slo_name" {
  description = "Nome do SLO de latência"
  value       = try(google_monitoring_slo.latency[0].name, null)
}

# Outputs de configuração
output "container_image" {
  description = "Imagem do container em uso"
  value       = var.image
}

output "min_instances" {
  description = "Mínimo de instâncias configurado"
  value       = var.min_instances
}

output "max_instances" {
  description = "Máximo de instâncias configurado"
  value       = var.max_instances
}

output "cpu" {
  description = "CPU configurada"
  value       = var.cpu
}

output "memory" {
  description = "Memória configurada"
  value       = var.memory
}

output "concurrency" {
  description = "Concorrência configurada"
  value       = var.concurrency
}

# Outputs de secrets
output "secrets_used" {
  description = "Lista de secrets utilizados"
  value       = keys(var.secrets)
}

# Outputs de Cloud SQL
output "cloud_sql_connections" {
  description = "Conexões Cloud SQL configuradas"
  value       = var.cloud_sql_connections
}

# Outputs para integração com outros módulos
output "service_url_with_protocol" {
  description = "URL completa do serviço (para uso em outros módulos)"
  value       = google_cloud_run_v2_service.main.uri
}

output "service_hostname" {
  description = "Hostname do serviço (sem protocolo)"
  value       = replace(replace(google_cloud_run_v2_service.main.uri, "https://", ""), "http://", "")
}

# Outputs de diagnóstico
output "terraform_module_info" {
  description = "Informações do módulo Terraform"
  value = {
    module_name    = "cloud-run"
    version       = "1.0"
    environment   = var.environment
    service       = var.service_name
  }
}