terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
  
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "helm" {
  kubernetes {
    host                   = module.gke.cluster_endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = module.gke.cluster_endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
}

data "google_client_config" "default" {}

locals {
  tags = {
    environment = var.environment
    project     = "lgtm-stack"
    managed_by  = "terraform"
    lgpd        = "enabled"
  }
}

module "cloud_storage" {
  source = "../../modules/cloud-storage"
  
  project_id  = var.project_id
  environment = var.environment
  region      = var.region
  tags        = local.tags
}

module "gke" {
  source = "../../modules/gke"
  
  project_id   = var.project_id
  environment  = var.environment
  region       = var.region
  cluster_name = "${var.environment}-lgtm-cluster"
  tags         = local.tags
}

module "monitoring" {
  source = "../../modules/monitoring"
  
  project_id            = var.project_id
  environment           = var.environment
  region                = var.region
  loki_bucket_name      = module.cloud_storage.loki_bucket_name
  tempo_bucket_name     = module.cloud_storage.tempo_bucket_name
  prometheus_bucket_name = module.cloud_storage.prometheus_bucket_name
  tags                  = local.tags
  
  depends_on = [module.gke, module.cloud_storage]
}

output "gke_cluster_name" {
  value = module.gke.cluster_name
}

output "otel_collector_endpoint" {
  value       = module.monitoring.otel_collector_endpoint
  description = "OpenTelemetry Collector endpoint com sanitização LGPD"
}

output "grafana_service" {
  value = module.monitoring.grafana_service
}

output "loki_bucket" {
  value = module.cloud_storage.loki_bucket_name
}

output "tempo_bucket" {
  value = module.cloud_storage.tempo_bucket_name
}

output "prometheus_bucket" {
  value = module.cloud_storage.prometheus_bucket_name
}
