# GCP Project
project_id = "meu-projeto-dev-12345"
environment = "dev"
region      = "us-central1"

# Networking
subnet_cidr       = "10.0.0.0/20"
pods_cidr         = "10.1.0.0/14"
services_cidr     = "10.2.0.0/20"
enable_nat_gateway = false
enable_vpc_connector = true

# Storage - 30 dias de retenção
retention_days = 30
storage_lifecycle_rules = [
  {
    age    = 30
    action = "Delete"
  }
]

# Cloud SQL - Configuração mínima
db_tier        = "db-f1-micro"
db_disk_size   = 10
db_availability_type = "ZONAL"
db_deletion_protection = false

# GKE - Release channel RAPID para dev
gke_release_channel = "RAPID"

# Cloud Run - Scale to zero
cloud_run_memory = "256Mi"
cloud_run_min_instances = 0
cloud_run_max_instances = 10

# Firebase
grafana_url = "https://grafana-dev.meu-projeto-dev-12345.web.app"

# Labels específicas do ambiente
resource_labels = {
  cost-center = "engineering-dev"
  owner       = "backend-team-dev"
}