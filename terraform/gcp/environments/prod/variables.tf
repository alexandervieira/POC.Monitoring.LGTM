# Variáveis básicas
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        =string
  default     = "prod"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "domain" {
  description = "Production domain"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    environment = "prod"
    managed_by  = "terraform"
    project     = "contagem-acessos"
    cost-center = "engineering-prod"
    data-classification = "confidential"
    compliance = "lgpd,soc2"
  }
}

# Networking
variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.32.0.0/20"
}

variable "pods_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.33.0.0/14"
}

variable "services_cidr" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.34.0.0/20"
}

variable "master_authorized_networks" {
  description = "Master authorized networks for GKE"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal network"
    },
    {
      cidr_block   = "192.168.0.0/16"
      display_name = "VPN network"
    }
  ]
}

# Storage
variable "storage_class" {
  description = "Storage class for GCS buckets"
  type        = string
  default     = "STANDARD"
}

variable "retention_days" {
  description = "Retention days for logs and traces (LGPD compliance)"
  type        = number
  default     = 90  # 90 dias para LGPD
}

variable "storage_lifecycle_rules" {
  description = "Lifecycle rules for GCS buckets"
  type = list(object({
    age    = number
    action = string
    condition = optional(object({
      matches_storage_class = optional(list(string))
      num_newer_versions    = optional(number)
      with_state            = optional(string)
    }))
  }))
  default = [
    {
      age    = 30
      action = "Delete"
      condition = {
        matches_storage_class = ["STANDARD"]
      }
    },
    {
      age    = 60
      action = "Delete"
      condition = {
        matches_storage_class = ["NEARLINE"]
      }
    },
    {
      age    = 90
      action = "Delete"
    }
  ]
}

# KMS (CMEK)
variable "kms_key_id" {
  description = "KMS key ID for CMEK (primary)"
  type        = string
}

variable "kms_dr_key_id" {
  description = "KMS key ID for CMEK (DR region)"
  type        = string
}

# Cloud SQL
variable "database_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_15"
}

variable "db_tier" {
  description = "Cloud SQL tier"
  type        = string
  default     = "db-custom-2-7680"  # 2 vCPU, 7.5GB RAM
}

variable "db_disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "basecontagem"
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
      value = "500"
    },
    {
      name  = "log_statement"
      value = "ddl"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    },
    {
      name  = "shared_buffers"
      value = "2097152"  # 2GB
    },
    {
      name  = "work_mem"
      value = "16384"  # 16MB
    },
    {
      name  = "maintenance_work_mem"
      value = "524288"  # 512MB
    },
    {
      name  = "effective_cache_size"
      value = "6291456"  # 6GB
    },
    {
      name  = "random_page_cost"
      value = "1.1"
    },
    {
      name  = "autovacuum"
      value = "on"
    },
    {
      name  = "autovacuum_vacuum_scale_factor"
      value = "0.05"
    }
  ]
}

# Cloud Run API
variable "api_version" {
  description = "API version/tag for deployment"
  type        = string
}

variable "api_memory" {
  description = "API memory allocation"
  type        = string
  default     = "1Gi"
}

variable "api_cpu" {
  description = "API CPU allocation"
  type        = number
  default     = 2
}

variable "api_min_instances" {
  description = "Minimum API instances"
  type        = number
  default     = 3  # HA mínimo
}

variable "api_max_instances" {
  description = "Maximum API instances"
  type        = number
  default     = 50
}

variable "enable_canary" {
  description = "Enable canary deployments"
  type        = bool
  default     = true
}

# Firebase
variable "firebase_site_id" {
  description = "Firebase Hosting site ID"
  type        = string
  default     = ""
}

variable "content_security_policy" {
  description = "Content Security Policy header (strict)"
  type        = string
  default     = "default-src 'self'; script-src 'self' 'unsafe-inline' https://*.firebaseapp.com https://*.web.app https://*.googleapis.com https://*.googletagmanager.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self' https://*.googleapis.com https://*.firebaseapp.com https://*.web.app https://*.grafana.net wss://*.grafana.net https://*.google-analytics.com; frame-ancestors 'none'; base-uri 'self'; form-action 'self';"
}

# Monitoring
variable "alert_channels" {
  description = "Alert notification channels"
  type = list(object({
    type = string
    config = map(string)
  }))
  default = [
    {
      type = "email"
      config = {
        email_address = "alerts-prod@example.com"
      }
    },
    {
      type = "slack"
      config = {
        channel_name = "#alerts-prod"
        webhook_url  = "https://hooks.slack.com/services/xxx/yyy/zzz"
      }
    },
    {
      type = "pagerduty"
      config = {
        service_key = "pagerduty-key-here"
      }
    }
  ]
}

variable "monitoring_sa_email" {
  description = "Monitoring service account email"
  type        = string
}

variable "cloud_load_balancer_sa" {
  description = "Cloud Load Balancer service account"
  type        = string
  default     = "service-${PROJECT_NUMBER}@cloud-lb.iam.gserviceaccount.com"
}

# Budget and cost control
variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 2000
}

variable "budget_alert_thresholds" {
  description = "Budget alert thresholds"
  type        = list(number)
  default     = [0.5, 0.75, 0.9, 1.0]
}

# Security
variable "enable_iap" {
  description = "Enable Identity-Aware Proxy"
  type        = bool
  default     = true
}

variable "allowed_ips" {
  description = "Allowed IP ranges for IAP"
  type        = list(string)
  default     = [
    "10.0.0.0/8",     # Internal
    "192.168.0.0/16", # VPN
    "172.16.0.0/12"   # Corporate
  ]
}

variable "enable_vpc_service_controls" {
  description = "Enable VPC Service Controls"
  type        = bool
  default     = true
}

# Scaling
variable "enable_cluster_autoscaling" {
  description = "Enable GKE cluster autoscaling"
  type        = bool
  default     = true
}

variable "enable_vertical_pod_autoscaling" {
  description = "Enable vertical pod autoscaling"
  type        = bool
  default     = true
}

# Compliance
variable "enable_audit_logs" {
  description = "Enable audit logs for compliance"
  type        = bool
  default     = true
}

variable "audit_log_config" {
  description = "Audit log configuration"
  type = object({
    log_type = string
    exempted_members = list(string)
  })
  default = {
    log_type = "DATA_READ, DATA_WRITE, ADMIN_READ"
    exempted_members = []
  }
}

# DR and Backup
variable "enable_dr" {
  description = "Enable disaster recovery"
  type        = bool
  default     = true
}

variable "dr_region" {
  description = "Disaster recovery region"
  type        = string
  default     = "us-central1"
}

variable "backup_retention_days" {
  description = "Backup retention in days"
  type        = number
  default     = 30
}