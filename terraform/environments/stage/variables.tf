# Variáveis básicas
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "stage"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "domain" {
  description = "Base domain for the application"
  type        = string
  default     = "example.com"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    environment = "stage"
    managed_by  = "terraform"
    project     = "contagem-acessos"
    cost-center = "engineering-stage"
    data-classification = "internal"
  }
}

# Networking
variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.16.0.0/20"
}

variable "pods_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.17.0.0/14"
}

variable "services_cidr" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.18.0.0/20"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private instances"
  type        = bool
  default     = true
}

variable "enable_vpc_connector" {
  description = "Enable VPC Serverless Connector"
  type        = bool
  default     = true
}

# Storage
variable "storage_class" {
  description = "Storage class for GCS buckets"
  type        = string
  default     = "STANDARD"
}

variable "retention_days" {
  description = "Retention days for logs and traces"
  type        = number
  default     = 60  # 60 dias para stage
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
    }
  ]
}

variable "enable_cmek" {
  description = "Enable Customer Managed Encryption Keys"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ID for CMEK"
  type        = string
  default     = null
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
  default     = "db-g1-small"  # Pequeno para stage
}

variable "db_disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 20
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
      value = "100"
    },
    {
      name  = "log_statement"
      value = "ddl"
    },
    {
      name  = "log_min_duration_statement"
      value = "500"
    },
    {
      name  = "shared_buffers"
      value = "262144"  # 256MB
    },
    {
      name  = "work_mem"
      value = "4096"  # 4MB
    }
  ]
}

# Firebase
variable "firebase_site_id" {
  description = "Firebase Hosting site ID"
  type        = string
  default     = ""
}

variable "enable_ssr" {
  description = "Enable Server-Side Rendering"
  type        = bool
  default     = false
}

variable "content_security_policy" {
  description = "Content Security Policy header"
  type        = string
  default     = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.firebaseapp.com https://*.web.app https://*.googleapis.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self' https://*.googleapis.com https://*.firebaseapp.com https://*.web.app https://*.grafana.net wss://*.grafana.net; frame-ancestors 'self' https://*.firebaseapp.com https://*.web.app;"
}

# Load Balancer
variable "cloud_armor_policy" {
  description = "Cloud Armor policy name"
  type        = string
  default     = "stage-waf-policy"
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
        email_address = "alerts-stage@example.com"
      }
    },
    {
      type = "slack"
      config = {
        channel_name = "#alerts-stage"
        webhook_url  = "https://hooks.slack.com/services/xxx/yyy/zzz"
      }
    }
  ]
}

variable "monitoring_sa_email" {
  description = "Monitoring service account email"
  type        = string
  default     = null
}

# Backup
variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Backup schedule (cron)"
  type        = string
  default     = "0 2 * * *"  # 2 AM daily
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
  default     = []
}

variable "enable_vpc_service_controls" {
  description = "Enable VPC Service Controls"
  type        = bool
  default     = false
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

# Costs and budgets
variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 500
}

variable "budget_alert_thresholds" {
  description = "Budget alert thresholds"
  type        = list(number)
  default     = [0.5, 0.75, 0.9, 1.0]
}