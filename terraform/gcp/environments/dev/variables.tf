# Variáveis básicas
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    environment = "dev"
    managed_by  = "terraform"
    project     = "contagem-acessos"
  }
}

# Variáveis de Networking
variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.1.0.0/14"
}

variable "services_cidr" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.2.0.0/20"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private instances"
  type        = bool
  default     = false  # Dev não precisa de NAT
}

variable "enable_vpc_connector" {
  description = "Enable VPC Serverless Connector"
  type        = bool
  default     = true
}

# Variáveis de Storage
variable "storage_class" {
  description = "Storage class for GCS buckets"
  type        = string
  default     = "STANDARD"
}

variable "retention_days" {
  description = "Retention days for logs and traces"
  type        = number
  default     = 30  # 30 dias para dev
}

variable "storage_lifecycle_rules" {
  description = "Lifecycle rules for GCS buckets"
  type = list(object({
    age    = number
    action = string
  }))
  default = [
    {
      age    = 30
      action = "Delete"
    }
  ]
}

# Variáveis do Cloud SQL
variable "database_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_15"
}

variable "db_tier" {
  description = "Cloud SQL tier"
  type        = string
  default     = "db-f1-micro"  # Menor tier para dev
}

variable "db_disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 10
}

variable "db_disk_type" {
  description = "Database disk type (PD_SSD or PD_HDD)"
  type        = string
  default     = "PD_SSD"
}

variable "db_disk_autoresize" {
  description = "Enable disk auto-resize"
  type        = bool
  default     = true
}

variable "db_availability_type" {
  description = "Availability type (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"  # Zonal para dev
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false  # Desabilitado para dev (facilita cleanup)
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "basecontagem"
}

variable "db_backup_configuration" {
  description = "Backup configuration for Cloud SQL"
  type = object({
    enabled                        = bool
    start_time                     = string
    point_in_time_recovery_enabled = bool
    transaction_log_retention_days = number
    retained_backups               = number
  })
  default = {
    enabled                        = true
    start_time                     = "03:00"
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = 3
    retained_backups               = 3
  }
}

variable "database_flags" {
  description = "PostgreSQL database flags"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "max_connections"
      value = "50"
    },
    {
      name  = "log_statement"
      value = "ddl"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  ]
}

# Variáveis do GKE
variable "gke_release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "RAPID"  # RAPID para dev (novas features)
}

variable "gke_maintenance_start_time" {
  description = "Daily maintenance window start time"
  type        = string
  default     = "03:00"
}

# Variáveis do Cloud Run
variable "cloud_run_memory" {
  description = "Cloud Run service memory"
  type        = string
  default     = "256Mi"  # Memória reduzida para dev
}

variable "cloud_run_cpu" {
  description = "Cloud Run service CPU"
  type        = number
  default     = 1
}

variable "cloud_run_concurrency" {
  description = "Cloud Run service concurrency"
  type        = number
  default     = 50
}

variable "cloud_run_min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0  # Scale to zero em dev
}

variable "cloud_run_max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

# Variáveis do Firebase
variable "grafana_url" {
  description = "Grafana URL for frontend"
  type        = string
  default     = "https://grafana-dev.mydomain.com"
}

# Variáveis de monitoramento/alerts
variable "enable_iap_access" {
  description = "Enable IAP access for debugging"
  type        = bool
  default     = true  # Útil para dev
}

variable "enable_monitoring_alerts" {
  description = "Enable monitoring alerts"
  type        = bool
  default     = false  # Desabilitado para dev
}

variable "notification_channels" {
  description = "Notification channels for alerts"
  type        = list(string)
  default     = []
}

# Variáveis de rede avançadas
variable "additional_firewall_rules" {
  description = "Additional firewall rules"
  type = list(object({
    name          = string
    allow_protocol = string
    allow_ports   = list(string)
    source_ranges = list(string)
    target_tags   = list(string)
  }))
  default = []
}

# Variáveis de labels/annotations
variable "resource_labels" {
  description = "Additional resource labels"
  type        = map(string)
  default = {
    cost-center = "engineering"
    owner       = "backend-team"
  }
}