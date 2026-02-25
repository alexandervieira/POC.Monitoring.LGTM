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
  }
  
  backend "gcs" {
    bucket = "meu-projeto-global-terraform-state"
    prefix = "global"
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

# Bucket para armazenar estados do Terraform (um por ambiente)
resource "google_storage_bucket" "terraform_state_dev" {
  name          = "${var.project_id}-terraform-state-dev"
  location      = var.region
  storage_class = "STANDARD"
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 90  # Manter versões por 90 dias
    }
    action {
      type = "Delete"
    }
  }
  
  labels = {
    environment = "dev"
    managed_by  = "terraform-global"
    purpose     = "terraform-state"
  }
}

resource "google_storage_bucket" "terraform_state_stage" {
  name          = "${var.project_id}-terraform-state-stage"
  location      = var.region
  storage_class = "STANDARD"
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  labels = {
    environment = "stage"
    managed_by  = "terraform-global"
    purpose     = "terraform-state"
  }
}

resource "google_storage_bucket" "terraform_state_prod" {
  name          = "${var.project_id}-terraform-state-prod"
  location      = var.region
  storage_class = "STANDARD"
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 180  # Manter por mais tempo em prod
    }
    action {
      type = "Delete"
    }
  }
  
  # Proteção contra deleção acidental em prod
  force_destroy = false
  
  labels = {
    environment = "prod"
    managed_by  = "terraform-global"
    purpose     = "terraform-state"
  }
}

# Artifact Registry para imagens Docker
resource "google_artifact_registry_repository" "backend" {
  provider = google-beta
  
  location      = var.region
  repository_id = "backend"
  description   = "Docker repository for backend API"
  format        = "DOCKER"
  
  docker_config {
    immutable_tags = var.environment == "prod" ? true : false
  }
  
  cleanup_policies {
    id     = "keep-latest-10"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }
  
  cleanup_policies {
    id     = "delete-older-than-90-days"
    action = "DELETE"
    condition {
      older_than = "7776000s"  # 90 dias
    }
  }
  
  labels = {
    managed_by = "terraform-global"
  }
}

# Service Account para CI/CD (Cloud Build)
resource "google_service_account" "cloud_build" {
  account_id   = "cloud-build-deployer"
  display_name = "Cloud Build Deployer Service Account"
  description  = "Service account for Cloud Build deployments"
}

# Permissões para o Service Account do Cloud Build
resource "google_project_iam_member" "cloud_build_roles" {
  for_each = toset([
    "roles/run.admin",
    "roles/cloudsql.admin",
    "roles/container.admin",
    "roles/storage.admin",
    "roles/artifactregistry.admin",
    "roles/iam.serviceAccountUser",
    "roles/secretmanager.admin",
    "roles/firebasehosting.admin",
    "roles/monitoring.admin"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "run.googleapis.com",
    "storage.googleapis.com",
    "firebase.googleapis.com",
    "firebasehosting.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_on_destroy = false
}

# VPC Access Connector (serverless) - Shared
resource "google_vpc_access_connector" "serverless_connector" {
  for_each = toset(["dev", "stage", "prod"])
  
  name          = "serverless-connector-${each.key}"
  region        = var.region
  network       = "${each.key}-vpc"
  ip_cidr_range = var.serverless_connector_cidr[each.key]
  
  min_instances = each.key == "prod" ? 2 : 1
  max_instances = each.key == "prod" ? 10 : 3
  
  machine_type = each.key == "prod" ? "e2-micro" : "f1-micro"
  
  depends_on = [
    google_project_service.apis
  ]
}

# DNS Zone (se aplicável)
resource "google_dns_managed_zone" "main" {
  count = var.create_dns_zone ? 1 : 0
  
  name        = "main-zone"
  dns_name    = var.dns_name
  description = "Main DNS zone for ${var.dns_name}"
  
  labels = {
    managed_by = "terraform-global"
  }
}

# SSL Certificates (managed)
resource "google_compute_managed_ssl_certificate" "grafana" {
  for_each = toset(var.grafana_domains)
  
  name = "grafana-cert-${replace(each.value, ".", "-")}"
  
  managed {
    domains = [each.value]
  }
}

# KMS Key para CMEK (opcional)
resource "google_kms_key_ring" "main" {
  count = var.enable_cmek ? 1 : 0
  
  name     = "main-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "storage" {
  count = var.enable_cmek ? 1 : 0
  
  name            = "storage-key"
  key_ring        = google_kms_key_ring.main[0].id
  rotation_period = "7776000s"  # 90 dias
  
  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }
}

# Monitoring workspace
resource "google_monitoring_workspace" "main" {
  count = var.create_monitoring_workspace ? 1 : 0
  
  display_name = "LGTM Monitoring"
}

# Alerting policies globais
resource "google_monitoring_alert_policy" "cost_alert" {
  count = var.enable_cost_alerts ? 1 : 0
  
  display_name = "Daily Cost Alert"
  combiner     = "OR"
  
  conditions {
    display_name = "Daily cost exceeds threshold"
    
    condition_threshold {
      filter     = "metric.type=\"billing.googleapis.com/cost\" AND resource.type=\"global\""
      duration   = "3600s"
      comparison = "COMPARISON_GT"
      threshold_value = var.cost_alert_threshold
      
      aggregations {
        alignment_period     = "86400s"  # 1 dia
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["project_id"]
      }
    }
  }
  
  alert_strategy {
    auto_close = "86400s"
  }
  
  notification_channels = var.notification_channels
}

# Outputs globais
output "terraform_state_buckets" {
  value = {
    dev   = google_storage_bucket.terraform_state_dev.name
    stage = google_storage_bucket.terraform_state_stage.name
    prod  = google_storage_bucket.terraform_state_prod.name
  }
}

output "artifact_registry_repository" {
  value = google_artifact_registry_repository.backend.name
}

output "cloud_build_service_account" {
  value = google_service_account.cloud_build.email
}

output "serverless_connectors" {
  value = {
    for env, connector in google_vpc_access_connector.serverless_connector :
    env => connector.name
  }
}

output "grafana_certificates" {
  value = {
    for domain in var.grafana_domains :
    domain => "grafana-cert-${replace(domain, ".", "-")}"
  }
}