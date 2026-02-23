resource "google_storage_bucket" "loki" {
  name          = "${var.project_id}-${var.environment}-loki-logs"
  location      = var.region
  storage_class = "STANDARD"
  
  lifecycle_rule {
    condition {
      age = 90  # 90 dias para LGPD
    }
    action {
      type = "Delete"
    }
  }
  
  versioning {
    enabled = false
  }
  
  uniform_bucket_level_access = true
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
}