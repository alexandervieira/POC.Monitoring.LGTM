# Terraform configuration
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  
  backend "gcs" {
    # Configurado via backend.tf separado para permitir variáveis
  }
}

# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Data sources
data "google_project" "current" {}

# Módulo de Networking
module "networking" {
  source = "../../modules/networking"
  
  environment        = var.environment
  project_id         = var.project_id
  region             = var.region
  vpc_name           = "${var.environment}-vpc"
  subnet_cidr        = var.subnet_cidr
  pods_cidr          = var.pods_cidr
  services_cidr      = var.services_cidr
  enable_nat_gateway = var.enable_nat_gateway
  enable_vpc_connector = var.enable_vpc_connector
  
  tags = var.tags
}

# Módulo de Cloud Storage (Buckets para logs/traces)
module "cloud_storage" {
  source = "../../modules/cloud-storage"
  
  environment     = var.environment
  project_id      = var.project_id
  region          = var.region
  storage_class   = var.storage_class
  retention_days  = var.retention_days
  
  # Buckets específicos
  create_loki_bucket     = true
  create_tempo_bucket    = true
  create_prometheus_bucket = true
  create_backup_bucket   = var.environment == "prod" ? true : false
  
  # Lifecycle rules
  lifecycle_rules = var.storage_lifecycle_rules
  
  tags = var.tags
}

# Módulo do Cloud SQL (PostgreSQL)
module "cloud_sql" {
  source = "../../modules/cloud-sql"
  
  environment        = var.environment
  project_id         = var.project_id
  region             = var.region
  vpc_id             = module.networking.vpc_id
  vpc_self_link      = module.networking.vpc_self_link
  
  # Configuração da instância
  database_version   = var.database_version
  db_tier            = var.db_tier
  db_disk_size       = var.db_disk_size
  db_disk_type       = var.db_disk_type
  db_disk_autoresize = var.db_disk_autoresize
  availability_type  = var.db_availability_type
  deletion_protection = var.db_deletion_protection
  
  # Backup configuration
  backup_configuration = var.db_backup_configuration
  
  # Database and users
  database_name      = var.database_name
  app_user_password  = random_password.db_password.result
  
  # Private service access
  private_network    = module.networking.vpc_self_link
  
  # Flags do PostgreSQL
  database_flags = var.database_flags
  
  tags = var.tags
}

# Geração de senha aleatória para o banco
resource "random_password" "db_password" {
  length  = 24
  special = false
  # Não recriar a senha se já existir (evita mudanças desnecessárias)
  keepers = {
    environment = var.environment
  }
}

# Armazenar senha no Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password-${var.environment}"
  
  replication {
    auto {}
  }
  
  labels = var.tags
}

resource "google_secret_manager_secret_version" "db_password" {
  secret = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Módulo do GKE Autopilot
module "gke" {
  source = "../../modules/gke"
  
  environment        = var.environment
  project_id         = var.project_id
  region             = var.region
  cluster_name       = "${var.environment}-lgtm-cluster"
  
  # Rede
  network            = module.networking.vpc_name
  subnetwork         = module.networking.subnet_name
  pods_range_name    = module.networking.pods_range_name
  services_range_name = module.networking.services_range_name
  
  # Configuração do Autopilot
  enable_autopilot   = true
  release_channel    = var.gke_release_channel
  
  # Maintenance window
  maintenance_start_time = var.gke_maintenance_start_time
  
  # Workload Identity
  enable_workload_identity = true
  
  # Service Accounts
  create_lgtm_service_account = true
  lgtm_service_account_name   = "${var.environment}-lgtm-sa"
  
  # Permissões para o Service Account
  gcs_buckets = [
    module.cloud_storage.loki_bucket_name,
    module.cloud_storage.tempo_bucket_name,
    module.cloud_storage.prometheus_bucket_name
  ]
  
  tags = var.tags
}

# Módulo do Cloud Run (Backend API)
module "cloud_run" {
  source = "../../modules/cloud-run"
  
  environment    = var.environment
  project_id     = var.project_id
  region         = var.region
  service_name   = "apicontagem-${var.environment}"
  
  # Container image (será atualizado pelo Cloud Build)
  image = "us-central1-docker.pkg.dev/${var.project_id}/backend/apicontagem:latest"
  
  # Configuração de recursos
  memory         = var.cloud_run_memory
  cpu            = var.cloud_run_cpu
  concurrency    = var.cloud_run_concurrency
  min_instances  = var.cloud_run_min_instances
  max_instances  = var.cloud_run_max_instances
  
  # VPC Connector
  vpc_connector_enabled = var.enable_vpc_connector
  vpc_connector_name    = module.networking.vpc_connector_name
  
  # Cloud SQL connection
  cloud_sql_connections = [module.cloud_sql.instance_connection_name]
  
  # Environment variables
  env_vars = {
    ASPNETCORE_ENVIRONMENT = var.environment == "prod" ? "Production" : title(var.environment)
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://alloy.monitoring.svc.cluster.local:4317"
    OTEL_SERVICE_NAME = "apicontagem"
    DB_HOST = module.cloud_sql.private_ip_address
    DB_NAME = var.database_name
    DB_USER = "app_user"
  }
  
  # Secrets
  secrets = {
    DB_PASSWORD = {
      secret_id = google_secret_manager_secret.db_password.secret_id
      version   = "latest"
    }
  }
  
  # Health check
  health_check_config = {
    enabled              = true
    http_get_path        = "/health"
    initial_delay_seconds = 10
    period_seconds       = 30
    failure_threshold    = 3
  }
  
  # Ingress settings
  ingress = "all"  # Permite tráfego externo para testes em dev
  
  # IAM
  invoker_members = ["allUsers"]  # Público em dev
  
  tags = var.tags
}

# Módulo do Firebase Hosting (Frontend React)
module "firebase_hosting" {
  source = "../../modules/firebase-hosting"
  
  environment = var.environment
  project_id  = var.project_id
  
  # Configuração do hosting
  site_id     = "${var.project_id}-${var.environment}"
  app_display_name = "Contagem Acessos - ${var.environment}"
  
  # Headers de segurança
  security_headers = {
    "X-Frame-Options" = "SAMEORIGIN"
    "X-Content-Type-Options" = "nosniff"
    "Referrer-Policy" = "strict-origin-when-cross-origin"
    "Content-Security-Policy" = "frame-ancestors 'self' https://*.firebaseapp.com https://*.web.app;"
  }
  
  # Grafana URL para o frontend
  grafana_url = var.grafana_url
  
  tags = var.tags
}

# Outputs importantes
output "vpc_name" {
  value = module.networking.vpc_name
}

output "gke_cluster_name" {
  value = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  value = module.gke.cluster_endpoint
  sensitive = true
}

output "cloud_sql_instance_name" {
  value = module.cloud_sql.instance_name
}

output "cloud_sql_connection_name" {
  value = module.cloud_sql.instance_connection_name
}

output "cloud_sql_private_ip" {
  value = module.cloud_sql.private_ip_address
}

output "db_password_secret_id" {
  value = google_secret_manager_secret.db_password.secret_id
}

output "cloud_run_service_url" {
  value = module.cloud_run.service_url
}

output "loki_bucket_name" {
  value = module.cloud_storage.loki_bucket_name
}

output "tempo_bucket_name" {
  value = module.cloud_storage.tempo_bucket_name
}

output "prometheus_bucket_name" {
  value = module.cloud_storage.prometheus_bucket_name
}

output "firebase_hosting_url" {
  value = module.firebase_hosting.hosting_url
}

output "lgtm_service_account_email" {
  value = module.gke.lgtm_service_account_email
}

# Recursos adicionais para dev
resource "google_compute_firewall" "allow-iap-ssh" {
  count = var.enable_iap_access ? 1 : 0
  
  name    = "${var.environment}-allow-iap-ssh"
  network = module.networking.vpc_name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["35.235.240.0/20"]  # IAP range
  target_tags   = ["iap-ssh"]
}

# Monitoring alert policy para dev (opcional)
resource "google_monitoring_alert_policy" "api_down" {
  count = var.enable_monitoring_alerts ? 1 : 0
  
  display_name = "API Contagem Down - ${var.environment}"
  combiner     = "OR"
  
  conditions {
    display_name = "API endpoint health check failing"
    
    condition_threshold {
      filter     = "metric.type=\"run.googleapis.com/request_count\" AND resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"apicontagem-${var.environment}\" AND metric.labels.response_code_class=\"500\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 0
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  alert_strategy {
    auto_close = "3600s"
  }
  
  notification_channels = var.notification_channels
}