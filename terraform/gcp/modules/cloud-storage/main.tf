terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_storage_bucket" "loki" {
  name          = "${var.project_id}-${var.environment}-loki-logs"
  location      = var.region
  storage_class = "STANDARD"
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  versioning {
    enabled = false
  }
  
  uniform_bucket_level_access = true
  
  labels = var.tags
}

resource "google_storage_bucket" "tempo" {
  name          = "${var.project_id}-${var.environment}-tempo-traces"
  location      = var.region
  storage_class = "STANDARD"
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  uniform_bucket_level_access = true
  
  labels = var.tags
}

resource "google_storage_bucket" "prometheus" {
  name          = "${var.project_id}-${var.environment}-prometheus-metrics"
  location      = var.region
  storage_class = "STANDARD"
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  uniform_bucket_level_access = true
  
  labels = var.tags
}

output "loki_bucket_name" {
  value = google_storage_bucket.loki.name
}

output "tempo_bucket_name" {
  value = google_storage_bucket.tempo.name
}

output "prometheus_bucket_name" {
  value = google_storage_bucket.prometheus.name
}
