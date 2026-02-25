# GCP Project
project_id = "meu-projeto-stage-12345"
environment = "stage"
region      = "us-central1"
domain      = "example.com"

# Networking
subnet_cidr         = "10.16.0.0/20"
pods_cidr           = "10.17.0.0/14"
services_cidr       = "10.18.0.0/20"
enable_nat_gateway  = true
enable_vpc_connector = true

# Storage - 60 dias de retenção
retention_days = 60
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
  }
]

# Cloud SQL
db_tier        = "db-g1-small"
db_disk_size   = 20

# GKE
enable_cluster_autoscaling = true
enable_vertical_pod_autoscaling = true

# Cloud Run
enable_ssr = false  # SSR opcional

# Firebase
firebase_site_id = "meu-projeto-stage"
content_security_policy = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.firebaseapp.com https://*.web.app https://*.googleapis.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self' https://*.googleapis.com https://*.firebaseapp.com https://*.web.app https://*.grafana.net; frame-ancestors 'self' https://*.firebaseapp.com https://*.web.app;"

# Security
enable_iap = true
allowed_ips = [
  "192.168.0.0/16",  # VPN range
  "10.0.0.0/8"       # Internal range
]

# Budget
budget_amount = 500
budget_alert_thresholds = [0.5, 0.75, 0.9, 1.0]

# Tags específicas
tags = {
  environment     = "stage"
  managed_by      = "terraform"
  project         = "contagem-acessos"
  cost-center     = "engineering-stage"
  data-classification = "internal"
  backup-policy   = "daily"
  monitoring-tier = "standard"
}