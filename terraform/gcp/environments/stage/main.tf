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
    # Configurado via backend.tf
  }
}

# Providers
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
data "google_compute_network" "vpc" {
  name    = "${var.environment}-vpc"
  project = var.project_id
}

data "google_compute_subnetwork" "subnet" {
  name    = "${var.environment}-subnet"
  region  = var.region
  project = var.project_id
}

# Módulo de Networking (reutilizando recursos existentes)
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
  
  # Configuração específica para stage
  nat_num_addresses   = 2  # Mais endereços NAT para stage
  vpc_connector_machine_type = "e2-micro"
  vpc_connector_min_instances = 2
  vpc_connector_max_instances = 5
  
  tags = var.tags
}

# Módulo de Cloud Storage
module "cloud_storage" {
  source = "../../modules/cloud-storage"
  
  environment     = var.environment
  project_id      = var.project_id
  region          = var.region
  storage_class   = var.storage_class
  retention_days  = var.retention_days
  
  # Buckets para stage
  create_loki_bucket     = true
  create_tempo_bucket    = true
  create_prometheus_bucket = true
  create_backup_bucket   = true  # Backup habilitado para stage
  
  # Lifecycle rules
  lifecycle_rules = var.storage_lifecycle_rules
  
  # Versionamento habilitado para stage
  enable_versioning = true
  
  # CMEK para stage (opcional)
  enable_cmek = var.enable_cmek
  kms_key_id  = var.kms_key_id
  
  tags = var.tags
}

# Módulo do Cloud SQL
module "cloud_sql" {
  source = "../../modules/cloud-sql"
  
  environment        = var.environment
  project_id         = var.project_id
  region             = var.region
  vpc_id             = module.networking.vpc_id
  vpc_self_link      = module.networking.vpc_self_link
  
  # Configuração da instância (maior que dev)
  database_version   = var.database_version
  db_tier            = var.db_tier  # db-g1-small ou maior
  db_disk_size       = var.db_disk_size  # 20-50GB
  db_disk_type       = "PD_SSD"
  db_disk_autoresize = true
  availability_type  = "ZONAL"  # Zonal ainda, mas com backup
  deletion_protection = true  # Protegido contra deleção
  
  # Backup configuration
  backup_configuration = {
    enabled                        = true
    start_time                     = "03:00"
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = 7
    retained_backups               = 14  # 2 semanas de backups
  }
  
  # Database and users
  database_name      = var.database_name
  app_user_password  = random_password.db_password.result
  
  # Private service access
  private_network    = module.networking.vpc_self_link
  
  # Database flags
  database_flags = var.database_flags
  
  # Maintenance window
  maintenance_window = {
    day          = 7  # Sunday
    hour         = 4  # 4 AM
    update_track = "stable"
  }
  
  tags = var.tags
}

# Senha do banco
resource "random_password" "db_password" {
  length  = 32
  special = true
  min_special = 2
  keepers = {
    environment = var.environment
    rotation    = timestamp()  # Força rotação periódica
  }
}

# Secret Manager para senha
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
  release_channel    = "REGULAR"  # Regular para stage
  
  # Maintenance window
  maintenance_start_time = "04:00"
  maintenance_end_time   = "06:00"
  maintenance_recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
  
  # Workload Identity
  enable_workload_identity = true
  
  # Service Accounts
  create_lgtm_service_account = true
  lgtm_service_account_name   = "${var.environment}-lgtm-sa"
  
  # Permissões
  gcs_buckets = [
    module.cloud_storage.loki_bucket_name,
    module.cloud_storage.tempo_bucket_name,
    module.cloud_storage.prometheus_bucket_name,
    module.cloud_storage.backup_bucket_name
  ]
  
  # Configuração adicional para stage
  enable_cluster_autoscaling = true
  enable_vertical_pod_autoscaling = true
  enable_intranode_visibility = true
  enable_binary_authorization = false  # Opcional em stage
  
  tags = var.tags
}

# Módulo do Cloud Run (Backend API)
module "cloud_run" {
  source = "../../modules/cloud-run"
  
  environment    = var.environment
  project_id     = var.project_id
  region         = var.region
  service_name   = "apicontagem-${var.environment}"
  
  # Container image
  image = "us-central1-docker.pkg.dev/${var.project_id}/backend/apicontagem:stage-latest"
  
  # Recursos (médios para stage)
  memory         = "512Mi"
  cpu            = "1"
  concurrency    = 80
  min_instances  = 1  # Mínimo 1 para stage
  max_instances  = 20
  
  # VPC Connector
  vpc_connector_enabled = true
  vpc_connector_name    = module.networking.vpc_connector_name
  
  # Cloud SQL connection
  cloud_sql_connections = [module.cloud_sql.instance_connection_name]
  
  # Environment variables
  env_vars = {
    ASPNETCORE_ENVIRONMENT = "Staging"
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://alloy.monitoring.svc.cluster.local:4317"
    OTEL_SERVICE_NAME = "apicontagem"
    DB_HOST = module.cloud_sql.private_ip_address
    DB_NAME = var.database_name
    DB_USER = "app_user"
    LOG_LEVEL = "Information"
    METRICS_ENABLED = "true"
    TRACING_ENABLED = "true"
  }
  
  # Secrets
  secrets = {
    DB_PASSWORD = {
      secret_id = google_secret_manager_secret.db_password.secret_id
      version   = "latest"
    }
    API_KEY = {
      secret_id = "api-key-${var.environment}"
      version   = "latest"
    }
  }
  
  # Health checks
  health_check_config = {
    enabled              = true
    http_get_path        = "/health"
    initial_delay_seconds = 15
    period_seconds       = 30
    failure_threshold    = 3
  }
  
  # Probes
  startup_probe_enabled = true
  startup_probe_http_path = "/health/startup"
  liveness_probe_enabled = true
  liveness_probe_http_path = "/health/live"
  
  # Ingress settings
  ingress = "internal-and-cloud-load-balancing"  # Apenas interno + LB
  
  # IAM
  public_access = false  # Sem acesso público direto
  invoker_members = [
    "serviceAccount:${module.gke.lgtm_service_account_email}",
    "serviceAccount:${var.monitoring_sa_email}"
  ]
  
  # Keep warm
  keep_warm_enabled = true
  keep_warm_schedule = "*/5 * * * *"  # A cada 5 minutos
  keep_warm_sa_email = module.gke.lgtm_service_account_email
  
  # Métricas e SLOs
  create_metrics = true
  create_slo     = true
  slo_availability_goal = 0.99  # 99% disponibilidade
  slo_latency_goal = 0.95
  slo_latency_threshold_ms = 800  # 800ms
  
  tags = var.tags
}

# Módulo do Firebase Hosting
module "firebase_hosting" {
  source = "../../modules/firebase-hosting"
  
  environment = var.environment
  project_id  = var.project_id
  region      = var.region
  app_display_name = "Contagem Acessos - Stage"
  service_name = "frontend-${var.environment}"
  
  # Configuração do site
  site_id = var.firebase_site_id != "" ? var.firebase_site_id : "${var.project_id}-${var.environment}"
  
  # URLs
  grafana_url = "https://grafana-${var.environment}.${var.domain}"
  api_url     = module.cloud_run.service_url
  
  # SPA routing
  spa_routing = true
  clean_urls  = true
  
  # Domínio customizado para stage
  custom_domain = var.environment == "stage" ? "stage.${var.domain}" : null
  wait_dns_verification = true
  
  # Headers de segurança (completos para stage)
  security_headers = {
    "**" = {
      "X-Frame-Options" = "SAMEORIGIN"
      "X-Content-Type-Options" = "nosniff"
      "Referrer-Policy" = "strict-origin-when-cross-origin"
      "Permissions-Policy" = "geolocation=(), microphone=(), camera=()"
      "X-XSS-Protection" = "1; mode=block"
      "Content-Security-Policy" = var.content_security_policy
    }
    "*.js" = {
      "Cache-Control" = "public, max-age=31536000, immutable"
    }
    "*.css" = {
      "Cache-Control" = "public, max-age=31536000, immutable"
    }
    "*.png" = {
      "Cache-Control" = "public, max-age=31536000, immutable"
    }
  }
  
  # Cache config
  cache_control_max_age = 31536000  # 1 ano
  cdn_cache_control = {
    max_age       = 3600
    s_maxage      = 3600
    stale_while_revalidate = 86400
  }
  
  # Preview channel para PRs
  create_preview_channel = true
  preview_channel_ttl = "172800s"  # 2 dias
  
  # Assets bucket
  create_assets_bucket = true
  assets_public_read   = true
  assets_versioning    = true
  assets_retention_days = 60  # 60 dias para stage
  
  # Autenticação
  configure_auth = true
  enable_email_auth = true
  enable_anonymous_auth = false  # Desabilitado em stage
  
  # Security Rules
  firestore_rules = file("${path.module}/../../firestore.rules")
  storage_rules   = file("${path.module}/../../storage.rules")
  
  # SSR (opcional em stage)
  enable_ssr = var.enable_ssr
  ssr_runtime = "nodejs20"
  ssr_entry_point = "render"
  ssr_memory = "512Mi"
  ssr_min_instances = 1
  ssr_max_instances = 10
  
  # CI/CD
  create_deploy_sa = true
  generate_config_file = true
  generate_firebase_json = true
  
  tags = var.tags
}

# Load Balancer para expor os serviços
module "load_balancer" {
  source = "../../modules/load-balancer"
  
  environment = var.environment
  project_id  = var.project_id
  region      = var.region
  name_prefix = "${var.environment}-lb"
  
  # Domínios
  domains = [
    "api.${var.environment}.${var.domain}",
    "grafana-${var.environment}.${var.domain}"
  ]
  
  # Backends
  backends = {
    api = {
      service_name = module.cloud_run.service_name
      service_url  = module.cloud_run.service_url
      paths        = ["/api/*", "/health*", "/metrics*"]
    }
    grafana = {
      service_name = "grafana"  # Serviço do Kubernetes
      service_url  = null
      paths        = ["/*"]
      backend_type = "NEG"
      neg_name     = "grafana-neg"
    }
  }
  
  # SSL Certificate
  create_ssl_certificate = true
  ssl_certificate_domains = [
    "api.${var.environment}.${var.domain}",
    "grafana-${var.environment}.${var.domain}"
  ]
  
  # Cloud Armor (WAF) para stage
  enable_cloud_armor = true
  cloud_armor_policy = var.cloud_armor_policy
  
  # CDN
  enable_cdn = false  # CDN opcional em stage
  
  tags = var.tags
}

# Monitoring
module "monitoring" {
  source = "../../modules/monitoring"
  
  environment = var.environment
  project_id  = var.project_id
  region      = var.region
  
  # Alertas
  alert_channels = var.alert_channels
  
  # Dashboards
  create_dashboards = true
  dashboard_folder = "LGTM Stage"
  
  # Uptime checks
  uptime_checks = {
    api = {
      host = "api.${var.environment}.${var.domain}"
      path = "/health"
      expected_status = 200
    }
    grafana = {
      host = "grafana-${var.environment}.${var.domain}"
      path = "/api/health"
      expected_status = 200
    }
  }
  
  # SLOs
  slos = {
    api_availability = {
      service_name = module.cloud_run.service_name
      goal         = 0.99
      window       = "30d"
    }
    api_latency = {
      service_name = module.cloud_run.service_name
      goal         = 0.95
      threshold_ms = 800
      window       = "30d"
    }
  }
  
  tags = var.tags
}

# Outputs
output "api_url" {
  value = "https://api.${var.environment}.${var.domain}"
}

output "grafana_url" {
  value = "https://grafana-${var.environment}.${var.domain}"
}

output "frontend_url" {
  value = module.firebase_hosting.hosting_url
}

output "database_instance" {
  value = module.cloud_sql.instance_name
}

output "gke_cluster" {
  value = module.gke.cluster_name
}