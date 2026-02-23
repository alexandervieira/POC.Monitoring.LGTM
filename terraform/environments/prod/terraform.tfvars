# GCP Project
project_id = "meu-projeto-prod-12345"
environment = "prod"
region      = "us-central1"
domain      = "minhaempresa.com.br"

# KMS Keys (devem ser criadas previamente)
kms_key_id      = "projects/meu-projeto-prod-12345/locations/us-central1/keyRings/main/cryptoKeys/storage-key"
kms_dr_key_id   = "projects/meu-projeto-prod-12345/locations/us-central1/keyRings/dr/cryptoKeys/dr-key"

# API Version (deve ser atualizado a cada deploy)
api_version = "v1.2.3"

# Networking
subnet_cidr         = "10.32.0.0/20"
pods_cidr           = "10.33.0.0/14"
services_cidr       = "10.34.0.0/20"

master_authorized_networks = [
  {
    cidr_block   = "10.0.0.0/8"
    display_name = "Internal network"
  },
  {
    cidr_block   = "192.168.0.0/16"
    display_name = "VPN network"
  },
  {
    cidr_block   = "177.100.50.0/24"
    display_name = "Corporate office"
  }
]

# Storage - 90 dias (LGPD)
retention_days = 90
storage_lifecycle_rules = [
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

# Cloud SQL
db_tier        = "db-custom-4-15360"  # 4 vCPU, 15GB RAM
db_disk_size   = 200  # 200GB

# Cloud Run API
api_memory        = "2Gi"
api_cpu           = 2
api_min_instances = 3
api_max_instances = 100

# Firebase
firebase_site_id = "minhaempresa"
content_security_policy = "default-src 'self'; script-src 'self' 'unsafe-inline' https://*.firebaseapp.com https://*.web.app https://*.googleapis.com https://*.googletagmanager.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self' https://*.googleapis.com https://*.firebaseapp.com https://*.web.app https://*.grafana.net wss://*.grafana.net https://*.google-analytics.com; frame-ancestors 'none'; base-uri 'self'; form-action 'self';"

# Service Accounts (previamente criados)
monitoring_sa_email = "monitoring-prod@meu-projeto-prod-12345.iam.gserviceaccount.com"
cloud_load_balancer_sa = "service-123456789@cloud-lb.iam.gserviceaccount.com"

# Budget
budget_amount = 2000
budget_alert_thresholds = [0.5, 0.75, 0.9, 1.0]

# Security
enable_iap = true
allowed_ips = [
  "10.0.0.0/8",
  "192.168.0.0/16",
  "177.100.50.0/24"
]
enable_vpc_service_controls = true

# DR and Backup
enable_dr = true
dr_region = "us-central1"
backup_retention_days = 30

# Tags específicas
tags = {
  environment          = "prod"
  managed_by           = "terraform"
  project              = "contagem-acessos"
  cost-center          = "engineering-prod"
  data-classification  = "confidential"
  compliance           = "lgpd,soc2,iso27001"
  backup-policy        = "daily+weekly+monthly"
  monitoring-tier      = "premium"
  dr-policy            = "cross-region"
  sla-tier             = "gold"
}