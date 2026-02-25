resource "google_container_cluster" "autopilot" {
  name     = "${var.environment}-lgtm-cluster"
  location = var.region
  
  enable_autopilot = true
  
  network    = var.vpc_id
  subnetwork = var.subnet_id
  
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }
  
  # Workload Identity para acesso seguro ao GCS
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Release channel para updates automáticos
  release_channel {
    channel = var.environment == "prod" ? "STABLE" : "RAPID"
  }
  
  # Manutenção
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
}

# Service Accounts para os workloads
resource "google_service_account" "lgtm_sa" {
  account_id   = "${var.environment}-lgtm-sa"
  display_name = "LGTM Stack Service Account"
}

# Permissões para acessar GCS
resource "google_project_iam_member" "storage_object_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.lgtm_sa.email}"
}

# Workload Identity binding
resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.lgtm_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[monitoring/lgtm-stack]"
}