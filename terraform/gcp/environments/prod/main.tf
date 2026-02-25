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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
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

provider "kubernetes" {
  host                   = "https://${module.gke.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
}

# Data sources
data "google_project" "current" {}
data "google_client_config" "default" {}

data "google_compute_network" "vpc" {
  name    = "${var.environment}-vpc"
  project = var.project_id
}

data "google_compute_subnetwork" "subnet" {
  name    = "${var.environment}-subnet"
  region  = var.region
  project = var.project_id
}

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
  enable_nat_gateway = true
  enable_vpc_connector = true
  
  # Configuração para produção
  nat_num_addresses   = 5  # Múltiplos endereços NAT
  vpc_connector_machine_type = "e2-micro"
  vpc_connector_min_instances = 2
  vpc_connector_max_instances = 10
  
  # Flow logs para auditoria
  enable_flow_logs = true
  flow_logs_config = {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
  
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
  
  # Buckets para produção
  create_loki_bucket     = true
  create_tempo_bucket    = true
  create_prometheus_bucket = true
  create_backup_bucket   = true
  
  # Lifecycle rules
  lifecycle_rules = var.storage_lifecycle_rules
  
  # Versionamento obrigatório
  enable_versioning = true
  
  # CMEK obrigatório para produção
  enable_cmek = true
  kms_key_id  = var.kms_key_id
  
  # Object holds
  enable_object_holds = true
  
  # Bucket locking para compliance
  enable_bucket_lock = true
  retention_policy = {
    retention_period = var.retention_days * 86400  # em segundos
    is_locked        = true
  }
  
  tags = var.tags
}

# Módulo do Cloud SQL (HA)
module "cloud_sql" {
  source = "../../modules/cloud-sql"
  
  environment        = var.environment
  project_id         = var.project_id
  region             = var.region
  vpc_id             = module.networking.vpc_id
  vpc_self_link      = module.networking.vpc_self_link
  
  # Configuração da instância (HA)
  database_version   = var.database_version
  db_tier            = var.db_tier  # db-custom-2-7680 ou maior
  db_disk_size       = var.db_disk_size  # 100GB+
  db_disk_type       = "PD_SSD"
  db_disk_autoresize = true
  availability_type  = "REGIONAL"  # HA entre zonas
  deletion_protection = true
  
  # Backup configuration (completo)
  backup_configuration = {
    enabled                        = true
    start_time                     = "02:00"
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = 7
    retained_backups               = 30  # 30 dias de backups
    location                       = "us"  # Multi-região
  }
  
  # Database and users
  database_name      = var.database_name
  app_user_password  = random_password.db_password.result
  
  # Private service access
  private_network    = module.networking.vpc_self_link
  
  # Database flags otimizados
  database_flags = var.database_flags
  
  # Maintenance window
  maintenance_window = {
    day          = 7  # Sunday
    hour         = 3  # 3 AM
    update_track = "stable"
  }
  
  # Read replicas para produção
  read_replicas = var.environment == "prod" ? [
    {
      name             = "${var.environment}-postgres-replica-1"
      tier             = var.db_tier
      zone             = "${var.region}-b"
      availability_type = "ZONAL"
    },
    {
      name             = "${var.environment}-postgres-replica-2"
      tier             = var.db_tier
      zone             = "${var.region}-c"
      availability_type = "ZONAL"
    }
  ] : []
  
  tags = var.tags
}

# Senha do banco (com rotação automática)
resource "random_password" "db_password" {
  length  = 48
  special = true
  min_special = 4
  keepers = {
    environment = var.environment
    rotation    = timestamp()
  }
}

# Secret Manager com CMEK
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password-${var.environment}"
  
  replication {
    user_managed {
      replicas {
        location = var.region
        customer_managed_encryption {
          kms_key_name = var.kms_key_id
        }
      }
      replicas {
        location = "us-central1"  # Replica para DR
        customer_managed_encryption {
          kms_key_name = var.kms_dr_key_id
        }
      }
    }
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
  release_channel    = "STABLE"  # Stable para produção
  
  # Maintenance window (restrito)
  maintenance_start_time = "05:00"
  maintenance_end_time   = "07:00"
  maintenance_recurrence = "FREQ=WEEKLY;BYDAY=SU"
  maintenance_exclusions = [
    {
      name       = "holiday-exclusion"
      start_time = "2024-12-24T00:00:00Z"
      end_time   = "2024-12-26T00:00:00Z"
    }
  ]
  
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
  
  # Configurações de produção
  enable_cluster_autoscaling = true
  enable_vertical_pod_autoscaling = true
  enable_intranode_visibility = true
  enable_binary_authorization = true
  binary_authorization_policy = "projects/${var.project_id}/policy"
  
  # Private cluster
  enable_private_nodes = true
  master_ipv4_cidr_block = "172.16.0.0/28"
  master_authorized_networks = var.master_authorized_networks
  
  # Database encryption
  database_encryption = {
    state      = "ENCRYPTED"
    key_name   = var.kms_key_id
  }
  
  # Shielded nodes
  enable_shielded_nodes = true
  
  # Resource usage export
  enable_resource_consumption_export = true
  
  # GKE Backup
  enable_backup = true
  backup_plan = {
    name       = "gke-backup-${var.environment}"
    region     = var.region
    schedule   = "0 3 * * *"  # 3 AM daily
    retention_days = 30
  }
  
  tags = var.tags
}

# Módulo do Cloud Run (Backend API)
module "cloud_run" {
  source = "../../modules/cloud-run"
  
  environment    = var.environment
  project_id     = var.project_id
  region         = var.region
  service_name   = "apicontagem-${var.environment}"
  
  # Container image (com tag específica, não latest)
  image = "us-central1-docker.pkg.dev/${var.project_id}/backend/apicontagem:${var.api_version}"
  
  # Recursos (adequados para produção)
  memory         = var.api_memory
  cpu            = var.api_cpu
  concurrency    = 100
  min_instances  = var.api_min_instances  # 2+ para HA
  max_instances  = var.api_max_instances  # 50+
  
  # VPC Connector
  vpc_connector_enabled = true
  vpc_connector_name    = module.networking.vpc_connector_name
  
  # Cloud SQL connection
  cloud_sql_connections = concat(
    [module.cloud_sql.instance_connection_name],
    module.cloud_sql.read_replica_connection_names
  )
  
  # Environment variables
  env_vars = {
    ASPNETCORE_ENVIRONMENT = "Production"
    OTEL_EXPORTER_OTLP_ENDPOINT = "http://alloy.monitoring.svc.cluster.local:4317"
    OTEL_SERVICE_NAME = "apicontagem"
    DB_HOST = module.cloud_sql.private_ip_address
    DB_READ_REPLICA_HOSTS = join(",", module.cloud_sql.read_replica_private_ips)
    DB_NAME = var.database_name
    DB_USER = "app_user"
    DB_POOL_SIZE = "20"
    LOG_LEVEL = "Warning"
    METRICS_ENABLED = "true"
    TRACING_ENABLED = "true"
    ENVIRONMENT = "production"
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
    JWT_SECRET = {
      secret_id = "jwt-secret-${var.environment}"
      version   = "latest"
    }
  }
  
  # Health checks (configuração rigorosa)
  health_check_config = {
    enabled              = true
    http_get_path        = "/health"
    initial_delay_seconds = 20
    period_seconds       = 15
    failure_threshold    = 2
  }
  
  # Probes
  startup_probe_enabled = true
  startup_probe_http_path = "/health/startup"
  startup_probe_initial_delay = 0
  startup_probe_period = 5
  startup_probe_failure_threshold = 5
  
  liveness_probe_enabled = true
  liveness_probe_http_path = "/health/live"
  liveness_probe_initial_delay = 30
  liveness_probe_period = 10
  liveness_probe_failure_threshold = 3
  
  # Ingress settings (apenas interno + Cloud Load Balancer)
  ingress = "internal-and-cloud-load-balancing"
  
  # IAM (restrito)
  public_access = false
  invoker_members = [
    "serviceAccount:${module.gke.lgtm_service_account_email}",
    "serviceAccount:${var.monitoring_sa_email}",
    "serviceAccount:${var.cloud_load_balancer_sa}"
  ]
  
  # Keep warm (essencial para produção)
  keep_warm_enabled = true
  keep_warm_schedule = "*/3 * * * *"  # A cada 3 minutos
  keep_warm_sa_email = module.gke.lgtm_service_account_email
  
  # Métricas e SLOs
  create_metrics = true
  create_slo     = true
  slo_availability_goal = 0.995  # 99.5% disponibilidade
  slo_latency_goal = 0.99
  slo_latency_threshold_ms = 500  # 500ms
  
  # Traffic splitting para canary
  traffic_splits = var.enable_canary ? [
    {
      type     = "TRAFFIC_SPLIT"
      percent  = 95
      revision = "latest"
    },
    {
      type     = "TRAFFIC_SPLIT"
      percent  = 5
      revision = "canary"
      tag      = "canary"
    }
  ] : []
  
  # Execution environment
  execution_environment = "gen2"
  enable_startup_cpu_boost = true
  session_affinity = false  # Desabilitado para melhor distribuição
  
  tags = var.tags
}

# Módulo do Firebase Hosting
module "firebase_hosting" {
  source = "../../modules/firebase-hosting"
  
  environment = var.environment
  project_id  = var.project_id
  region      = var.region
  app_display_name = "Contagem Acessos - Production"
  service_name = "frontend-${var.environment}"
  
  # Configuração do site
  site_id = var.firebase_site_id != "" ? var.firebase_site_id : "${var.project_id}"
  
  # URLs
  grafana_url = "https://grafana.${var.domain}"
  api_url     = "https://api.${var.domain}"
  
  # SPA routing
  spa_routing = true
  clean_urls  = true
  
  # Domínio customizado para produção
  custom_domain = var.domain
  wait_dns_verification = true
  
  # Headers de segurança (máxima segurança)
  security_headers = {
    "**" = {
      "X-Frame-Options" = "DENY"
      "X-Content-Type-Options" = "nosniff"
      "Referrer-Policy" = "strict-origin-when-cross-origin"
      "Permissions-Policy" = "geolocation=(), microphone=(), camera=(), payment=()"
      "X-XSS-Protection" = "1; mode=block"
      "Strict-Transport-Security" = "max-age=31536000; includeSubDomains; preload"
      "Content-Security-Policy" = var.content_security_policy
    }
    "*.js" = {
      "Cache-Control" = "public, max-age=31536000, immutable"
    }
    "*.css" = {
      "Cache-Control" = "public, max-age=31536000, immutable"
    }
  }
  
  # Cache config
  cache_control_max_age = 31536000
  cdn_cache_control = {
    max_age       = 3600
    s_maxage      = 3600
    stale_while_revalidate = 86400
  }
  
  # Assets bucket
  create_assets_bucket = true
  assets_public_read   = true
  assets_versioning    = true
  assets_retention_days = 90
  
  # Autenticação
  configure_auth = true
  enable_email_auth = true
  enable_anonymous_auth = false
  enable_mfa = true  # MFA obrigatório
  
  # Security Rules
  firestore_rules = file("${path.module}/../../firestore.rules")
  storage_rules   = file("${path.module}/../../storage.rules")
  
  # SSR (recomendado para produção)
  enable_ssr = true
  ssr_runtime = "nodejs20"
  ssr_entry_point = "render"
  ssr_memory = "1Gi"
  ssr_min_instances = 2
  ssr_max_instances = 20
  ssr_env_vars = {
    NODE_ENV = "production"
    API_URL  = "https://api.${var.domain}"
    GRAFANA_URL = "https://grafana.${var.domain}"
    CACHE_TTL = "300"
  }
  
  # CI/CD
  create_deploy_sa = true
  generate_config_file = true
  generate_firebase_json = true
  
  tags = var.tags
}

# Load Balancer Global
module "load_balancer" {
  source = "../../modules/load-balancer"
  
  environment = var.environment
  project_id  = var.project_id
  region      = var.region
  name_prefix = "${var.environment}-lb"
  
  # Domínios
  domains = [
    "api.${var.domain}",
    "grafana.${var.domain}",
    var.domain
  ]
  
  # Backends
  backends = {
    api = {
      service_name = module.cloud_run.service_name
      service_url  = module.cloud_run.service_url
      paths        = ["/api/*", "/health*", "/metrics*"]
      protocol     = "HTTP2"
    }
    grafana = {
      service_name = "grafana"
      service_url  = null
      paths        = ["/grafana/*", "/explore/*", "/d/*"]
      backend_type = "NEG"
      neg_name     = "grafana-neg"
      protocol     = "HTTP"
    }
    frontend = {
      service_name = module.firebase_hosting.site_id
      service_url  = module.firebase_hosting.hosting_url
      paths        = ["/*"]
      backend_type = "INTERNET_NETWORK_ENDPOINT_GROUP"
      protocol     = "HTTPS"
    }
  }
  
  # SSL Certificate (managed)
  create_ssl_certificate = true
  ssl_certificate_domains = [
    "api.${var.domain}",
    "grafana.${var.domain}",
    var.domain
  ]
  ssl_policy = "modern-ssl-policy"
  
  # Cloud Armor (WAF) com regras avançadas
  enable_cloud_armor = true
  cloud_armor_policy = "prod-waf-policy"
  cloud_armor_rules = [
    {
      name        = "block-xss"
      priority    = 1000
      action      = "deny(403)"
      expression  = "evaluatePreconfiguredExpr('xss-v33-stable')"
    },
    {
      name        = "block-sqli"
      priority    = 2000
      action      = "deny(403)"
      expression  = "evaluatePreconfiguredExpr('sqli-v33-stable')"
    },
    {
      name        = "block-lfi"
      priority    = 3000
      action      = "deny(403)"
      expression  = "evaluatePreconfiguredExpr('lfi-v33-stable')"
    },
    {
      name        = "rate-limit"
      priority    = 4000
      action      = "rate_based_ban"
      expression  = "true"
      rate_limit_options = {
        rate_limit_threshold = 100
        interval_sec        = 60
        ban_threshold       = 300
        ban_duration_sec    = 3600
      }
    }
  ]
  
  # CDN
  enable_cdn = true
  cdn_config = {
    cache_policy = {
      cache_mode            = "USE_ORIGIN_HEADERS"
      client_ttl            = 3600
      default_ttl           = 3600
      max_ttl               = 86400
      negative_caching      = true
      serve_while_stale     = true
    }
    compression_mode = "AUTOMATIC"
  }
  
  # Logging
  enable_logging = true
  logging_config = {
    enable      = true
    sample_rate = 1.0
  }
  
  tags = var.tags
}

# Módulo de Monitoring
module "monitoring" {
  source = "../../modules/monitoring"
  
  environment = var.environment
  project_id  = var.project_id
  region      = var.region
  
  # Alertas (múltiplos canais)
  alert_channels = var.alert_channels
  
  # Dashboards
  create_dashboards = true
  dashboard_folder = "LGTM Production"
  
  # Uptime checks (global)
  uptime_checks = {
    api = {
      host = "api.${var.domain}"
      path = "/health"
      expected_status = 200
      regions = ["USA", "EUROPE", "ASIA_PACIFIC"]
    }
    grafana = {
      host = "grafana.${var.domain}"
      path = "/api/health"
      expected_status = 200
      regions = ["USA", "EUROPE"]
    }
    frontend = {
      host = var.domain
      path = "/"
      expected_status = 200
      regions = ["USA", "EUROPE", "ASIA_PACIFIC", "SOUTH_AMERICA"]
    }
  }
  
  # SLOs (Service Level Objectives)
  slos = {
    api_availability = {
      service_name = module.cloud_run.service_name
      goal         = 0.995
      window       = "30d"
    }
    api_latency = {
      service_name = module.cloud_run.service_name
      goal         = 0.99
      threshold_ms = 500
      window       = "30d"
    }
    frontend_availability = {
      service_name = module.firebase_hosting.site_id
      goal         = 0.999
      window       = "30d"
    }
  }
  
  # Alert policies
  alert_policies = {
    high_error_rate = {
      display_name = "High Error Rate"
      conditions = [{
        filter = "metric.type=\"run.googleapis.com/request_count\" AND resource.labels.service_name=\"${module.cloud_run.service_name}\" AND metric.labels.response_code_class=\"500\""
        threshold = 0.01
        duration = "300s"
      }]
      severity = "critical"
    }
    high_latency = {
      display_name = "High Latency"
      conditions = [{
        filter = "metric.type=\"run.googleapis.com/request_latencies\" AND resource.labels.service_name=\"${module.cloud_run.service_name}\""
        threshold = 500
        duration = "300s"
        aggregations = {
          alignment_period = "60s"
          per_series_aligner = "ALIGN_PERCENTILE_99"
        }
      }]
      severity = "warning"
    }
    disk_full = {
      display_name = "Database Disk Nearly Full"
      conditions = [{
        filter = "metric.type=\"cloudsql.googleapis.com/database/disk/bytes_used\" AND resource.labels.database_id=\"${module.cloud_sql.instance_id}\""
        threshold = 0.85
        duration = "3600s"
        aggregations = {
          alignment_period = "300s"
          per_series_aligner = "ALIGN_MAX"
        }
      }]
      severity = "critical"
    }
  }
  
  tags = var.tags
}

# Módulo de Backup e DR
module "backup" {
  source = "../../modules/backup"
  
  environment = var.environment
  project_id  = var.project_id
  region      = var.region
  dr_region   = "us-central1"  # Região de DR
  
  # Cloud SQL backups
  sql_instance_name = module.cloud_sql.instance_name
  
  # GKE backups
  gke_cluster_name = module.gke.cluster_name
  gke_backup_plan = {
    name            = "gke-backup-prod"
    schedule        = "0 4 * * *"
    retention_days  = 30
    backup_region   = var.region
    dr_backup_region = "us-central1"
  }
  
  # Filestore backups (se aplicável)
  enable_filestore_backup = false
  
  # Disaster Recovery
  dr_config = {
    enabled              = true
    failover_region      = "us-central1"
    auto_failover        = false  # Manual failover
    replication_schedule = "0 */6 * * *"  # A cada 6 horas
  }
  
  tags = var.tags
}

# Outputs
output "api_url" {
  value = "https://api.${var.domain}"
}

output "grafana_url" {
  value = "https://grafana.${var.domain}"
}

output "frontend_url" {
  value = "https://${var.domain}"
}

output "database_instance" {
  value = module.cloud_sql.instance_name
}

output "database_read_replicas" {
  value = module.cloud_sql.read_replica_names
}

output "gke_cluster" {
  value = module.gke.cluster_name
}

output "monitoring_dashboard" {
  value = module.monitoring.dashboard_url
}

output "slo_documentation" {
  value = module.monitoring.slo_documentation
}