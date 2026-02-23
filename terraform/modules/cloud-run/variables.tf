# Variáveis obrigatórias
variable "service_name" {
  description = "Nome do serviço Cloud Run"
  type        = string
}

variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "region" {
  description = "Região do GCP"
  type        = string
}

variable "environment" {
  description = "Nome do ambiente (dev, stage, prod)"
  type        = string
}

variable "image" {
  description = "Imagem do container no Artifact Registry"
  type        = string
}

# Variáveis de recursos
variable "cpu" {
  description = "Quantidade de CPU (1, 2, 4, etc)"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Quantidade de memória (256Mi, 512Mi, 1Gi, etc)"
  type        = string
  default     = "512Mi"
}

variable "concurrency" {
  description = "Número máximo de requisições concorrentes por instância"
  type        = number
  default     = 80
}

variable "min_instances" {
  description = "Número mínimo de instâncias (0 para scale to zero)"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Número máximo de instâncias"
  type        = number
  default     = 10
}

variable "container_port" {
  description = "Porta do container"
  type        = number
  default     = 8080
}

variable "request_timeout" {
  description = "Timeout das requisições em segundos"
  type        = number
  default     = 300
}

# Variáveis de configuração
variable "env_vars" {
  description = "Variáveis de ambiente (mapa chave-valor)"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets do Secret Manager"
  type = map(object({
    secret_id = string
    version   = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}

# VPC Connector
variable "vpc_connector_enabled" {
  description = "Habilitar VPC Serverless Connector"
  type        = bool
  default     = false
}

variable "vpc_connector_name" {
  description = "Nome do VPC Serverless Connector"
  type        = string
  default     = null
}

# Cloud SQL
variable "cloud_sql_connections" {
  description = "Lista de conexões Cloud SQL (formato: project:region:instance)"
  type        = list(string)
  default     = []
}

# Health Check
variable "health_check_config" {
  description = "Configuração do health check"
  type = object({
    enabled              = bool
    http_get_path        = string
    initial_delay_seconds = number
    period_seconds       = number
    failure_threshold    = number
  })
  default = {
    enabled              = true
    http_get_path        = "/health"
    initial_delay_seconds = 10
    period_seconds       = 30
    failure_threshold    = 3
  }
}

# Startup Probe
variable "startup_probe_enabled" {
  description = "Habilitar startup probe"
  type        = bool
  default     = true
}

variable "startup_probe_initial_delay" {
  description = "Delay inicial do startup probe em segundos"
  type        = number
  default     = 0
}

variable "startup_probe_timeout" {
  description = "Timeout do startup probe em segundos"
  type        = number
  default     = 5
}

variable "startup_probe_period" {
  description = "Período do startup probe em segundos"
  type        = number
  default     = 10
}

variable "startup_probe_failure_threshold" {
  description = "Threshold de falha do startup probe"
  type        = number
  default     = 3
}

variable "startup_probe_http_path" {
  description = "Path HTTP para startup probe (null para TCP)"
  type        = string
  default     = "/health/startup"
}

variable "startup_probe_tcp_port" {
  description = "Porta TCP para startup probe (null para HTTP)"
  type        = number
  default     = null
}

# Liveness Probe
variable "liveness_probe_enabled" {
  description = "Habilitar liveness probe"
  type        = bool
  default     = true
}

variable "liveness_probe_initial_delay" {
  description = "Delay inicial do liveness probe em segundos"
  type        = number
  default     = 30
}

variable "liveness_probe_timeout" {
  description = "Timeout do liveness probe em segundos"
  type        = number
  default     = 5
}

variable "liveness_probe_period" {
  description = "Período do liveness probe em segundos"
  type        = number
  default     = 30
}

variable "liveness_probe_failure_threshold" {
  description = "Threshold de falha do liveness probe"
  type        = number
  default     = 3
}

variable "liveness_probe_http_path" {
  description = "Path HTTP para liveness probe"
  type        = string
  default     = "/health/live"
}

# IAM e Acesso
variable "public_access" {
  description = "Permitir acesso público ao serviço"
  type        = bool
  default     = false
}

variable "invoker_members" {
  description = "Membros com permissão de invocar o serviço"
  type        = list(string)
  default     = []
}

variable "invoker_members_map" {
  description = "Mapeamento de membros para roles específicas"
  type = map(object({
    role   = string
    member = string
  }))
  default = {}
}

# Domain Mapping
variable "custom_domain" {
  description = "Domínio customizado para o serviço"
  type        = string
  default     = null
}

# Service Account
variable "service_account_email" {
  description = "Email da service account (null para usar a default)"
  type        = string
  default     = null
}

# Execution Environment
variable "execution_environment" {
  description = "Ambiente de execução (gen1 ou gen2)"
  type        = string
  default     = "gen2"
  
  validation {
    condition     = contains(["gen1", "gen2"], var.execution_environment)
    error_message = "Execution environment must be gen1 or gen2."
  }
}

# Configurações avançadas
variable "enable_startup_cpu_boost" {
  description = "Habilitar CPU boost no startup"
  type        = bool
  default     = true
}

variable "enable_cpu_throttling" {
  description = "Habilitar throttling de CPU"
  type        = bool
  default     = true
}

variable "session_affinity" {
  description = "Habilitar session affinity"
  type        = bool
  default     = false
}

variable "startup_command" {
  description = "Comando de inicialização do container"
  type        = list(string)
  default     = null
}

variable "startup_args" {
  description = "Argumentos para o comando de inicialização"
  type        = list(string)
  default     = null
}

# Volumes
variable "volumes" {
  description = "Volumes para montar no container"
  type = list(object({
    name = string
    secret = optional(object({
      secret_name = string
      path        = string
      version     = string
      mode        = number
    }))
    cloud_sql_instance = optional(object({
      instances = list(string)
    }))
  }))
  default = []
}

variable "volume_mounts" {
  description = "Mount points para volumes"
  type = list(object({
    name       = string
    mount_path = string
  }))
  default = []
}

# Traffic splitting
variable "traffic_splits" {
  description = "Divisão de tráfego entre revisões"
  type = list(object({
    type     = string
    percent  = number
    revision = optional(string)
    tag      = optional(string)
  }))
  default = []
}

# Client info
variable "client_name" {
  description = "Nome do cliente que gerencia o serviço"
  type        = string
  default     = "terraform"
}

variable "client_version" {
  description = "Versão do cliente"
  type        = string
  default     = "1.0"
}

# Keep warm
variable "keep_warm_enabled" {
  description = "Habilitar Cloud Scheduler para manter instâncias aquecidas"
  type        = bool
  default     = false
}

variable "keep_warm_schedule" {
  description = "Cron schedule para o keep-warm job"
  type        = string
  default     = "*/5 * * * *"  # A cada 5 minutos
}

variable "keep_warm_sa_email" {
  description = "Service account email para keep-warm (opcional)"
  type        = string
  default     = null
}

# Métricas e SLOs
variable "create_metrics" {
  description = "Criar métricas baseadas em logs"
  type        = bool
  default     = false
}

variable "create_slo" {
  description = "Criar SLOs para o serviço"
  type        = bool
  default     = false
}

variable "slo_service_id" {
  description = "ID do serviço no Monitoring (para SLOs)"
  type        = string
  default     = null
}

variable "slo_availability_goal" {
  description = "Meta de disponibilidade (99.9 = 0.999)"
  type        = number
  default     = 0.999
}

variable "slo_latency_goal" {
  description = "Meta de latência (0.95 = 95% dentro do threshold)"
  type        = number
  default     = 0.95
}

variable "slo_latency_threshold_ms" {
  description = "Threshold de latência em milissegundos"
  type        = number
  default     = 500
}

variable "slo_calendar_period" {
  description = "Período do calendário para SLO"
  type        = string
  default     = "MONTH"
  
  validation {
    condition     = contains(["DAY", "WEEK", "FORTNIGHT", "MONTH"], var.slo_calendar_period)
    error_message = "Calendar period must be DAY, WEEK, FORTNIGHT, or MONTH."
  }
}

# Dependências
variable "module_depends_on" {
  description = "Dependências do módulo"
  type        = any
  default     = []
}