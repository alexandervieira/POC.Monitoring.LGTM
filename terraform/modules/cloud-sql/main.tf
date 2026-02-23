resource "google_sql_database_instance" "postgres" {
  name             = "${var.environment}-postgres"
  database_version = "POSTGRES_15"
  region           = var.region
  
  settings {
    tier              = var.db_tier
    disk_type         = "PD_SSD"
    disk_size         = var.db_disk_size
    disk_autoresize   = true
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"
    
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = var.environment == "prod" ? 30 : 7
      }
    }
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_id
      
      authorized_networks {
        name  = "cloud-run-cidr"
        value = "10.0.0.0/8"  # Range do Cloud Run Serverless VPC Connector
      }
    }
  }
  
  deletion_protection = var.environment == "prod" ? true : false
}

resource "google_sql_database" "database" {
  name     = "basecontagem"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "app_user" {
  name     = "app_user"
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}