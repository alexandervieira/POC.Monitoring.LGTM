# Módulo Firebase Hosting para deploy do frontend React

# Data sources
data "google_project" "current" {}

# Enable Firebase APIs
resource "google_project_service" "firebase" {
  for_each = toset([
    "firebase.googleapis.com",
    "firebasehosting.googleapis.com",
    "firebaseanalytics.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "firebaserules.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_on_destroy = false
}

# Create Firebase project (if not already enabled)
resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id
  
  depends_on = [google_project_service.firebase]
}

# Create Firebase Web App
resource "google_firebase_web_app" "main" {
  provider = google-beta
  project  = var.project_id
  
  display_name = var.app_display_name
  deletion_policy = var.environment == "prod" ? "DELETE" : "ABANDON"
  
  depends_on = [google_firebase_project.default]
}

# Generate Firebase configuration for web app
resource "google_firebase_web_app_config" "main" {
  provider   = google-beta
  project    = var.project_id
  web_app_id = google_firebase_web_app.main.app_id
  
  depends_on = [google_firebase_web_app.main]
}

# Create Firebase Hosting site
resource "google_firebase_hosting_site" "main" {
  provider = google-beta
  project  = var.project_id
  site_id  = var.site_id != "" ? var.site_id : "${var.project_id}-${var.environment}"
  
  app_id = google_firebase_web_app.main.app_id
  
  labels = merge(var.tags, {
    environment = var.environment
    app_type    = "react-frontend"
  })
  
  depends_on = [google_firebase_web_app.main]
}

# Firebase Hosting channel for preview deployments (optional)
resource "google_firebase_hosting_channel" "preview" {
  count = var.create_preview_channel ? 1 : 0
  
  provider = google-beta
  project  = var.project_id
  site_id  = google_firebase_hosting_site.main.site_id
  channel_id = "preview"
  
  ttl = var.preview_channel_ttl
  
  labels = merge(var.tags, {
    environment = var.environment
    channel     = "preview"
  })
}

# Firebase Hosting version for main channel
resource "google_firebase_hosting_version" "main" {
  provider = google-beta
  project  = var.project_id
  site_id  = google_firebase_hosting_site.main.site_id
  
  config {
    # Rewrites para SPA (React Router)
    dynamic "rewrite" {
      for_each = var.spa_routing ? [1] : []
      content {
        glob = "**"
        path = "/index.html"
      }
    }
    
    # Redirects customizados
    dynamic "redirect" {
      for_each = var.redirects
      content {
        glob        = redirect.value.glob
        location    = redirect.value.location
        status_code = redirect.value.status_code
      }
    }
    
    # Headers de segurança
    dynamic "header" {
      for_each = var.security_headers
      content {
        glob = header.value.glob != null ? header.value.glob : "**"
        
        dynamic "header" {
          for_each = header.value.headers
          content {
            key   = header.key
            value = header.value
          }
        }
      }
    }
    
    # Clean URLs (remover .html extension)
    dynamic "clean_url" {
      for_each = var.clean_urls ? [1] : []
      content {
        clean_url = true
      }
    }
    
    # Trailing slash behavior
    trailing_slash_behavior = var.trailing_slash_behavior
  }
  
  depends_on = [google_firebase_hosting_site.main]
}

# Release para o canal principal (produção)
resource "google_firebase_hosting_release" "main" {
  provider = google-beta
  project  = var.project_id
  site_id  = google_firebase_hosting_site.main.site_id
  version_name = google_firebase_hosting_version.main.id
  message  = "Deploy ${var.environment} - ${formatdate("YYYY-MM-DD hh:mm:ss", timestamp())}"
  type     = "DEPLOY"
  
  depends_on = [google_firebase_hosting_version.main]
}

# Channel para desenvolvimento (live-dev)
resource "google_firebase_hosting_channel" "dev" {
  count = var.environment == "dev" ? 1 : 0
  
  provider = google-beta
  project  = var.project_id
  site_id  = google_firebase_hosting_site.main.site_id
  channel_id = "live-dev"
  
  labels = merge(var.tags, {
    environment = "dev"
    channel     = "live-dev"
  })
}

# Release para o canal de desenvolvimento
resource "google_firebase_hosting_release" "dev" {
  count = var.environment == "dev" ? 1 : 0
  
  provider = google-beta
  project  = var.project_id
  site_id  = google_firebase_hosting_site.main.site_id
  version_name = google_firebase_hosting_version.main.id
  channel_id = google_firebase_hosting_channel.dev[0].channel_id
  message  = "Dev Deploy - ${formatdate("YYYY-MM-DD hh:mm:ss", timestamp())}"
  type     = "DEPLOY"
  
  depends_on = [
    google_firebase_hosting_version.main,
    google_firebase_hosting_channel.dev
  ]
}

# Custom domain (opcional)
resource "google_firebase_hosting_custom_domain" "main" {
  count = var.custom_domain != null ? 1 : 0
  
  provider = google-beta
  project  = var.project_id
  site_id  = google_firebase_hosting_site.main.site_id
  custom_domain = var.custom_domain
  
  # Certificado SSL automático
  cert_preference = "GROUPED"
  
  # Wait for DNS verification
  wait_dns_verification = var.wait_dns_verification
  
  labels = merge(var.tags, {
    environment = var.environment
    domain      = replace(var.custom_domain, ".", "-")
  })
  
  depends_on = [google_firebase_hosting_site.main]
}

# Cloud Storage bucket para assets estáticos (opcional)
resource "google_storage_bucket" "assets" {
  count = var.create_assets_bucket ? 1 : 0
  
  name          = "${var.project_id}-${var.environment}-frontend-assets"
  location      = var.region
  storage_class = var.assets_storage_class
  
  uniform_bucket_level_access = true
  
  cors {
    origin          = var.assets_cors_origins
    method          = ["GET", "HEAD", "OPTIONS"]
    response_header = ["Content-Type", "Content-Length", "Content-Encoding"]
    max_age_seconds = 3600
  }
  
  versioning {
    enabled = var.assets_versioning
  }
  
  lifecycle_rule {
    condition {
      age = var.assets_retention_days
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge(var.tags, {
    environment = var.environment
    purpose     = "frontend-assets"
  })
}

# Make bucket public readable
resource "google_storage_bucket_iam_member" "assets_public" {
  count = var.create_assets_bucket && var.assets_public_read ? 1 : 0
  
  bucket = google_storage_bucket.assets[0].name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Firebase Hosting association with Cloud Storage bucket
resource "google_firebase_hosting_version" "assets" {
  count = var.create_assets_bucket ? 1 : 0
  
  provider = google-beta
  project  = var.project_id
  site_id  = google_firebase_hosting_site.main.site_id
  
  config {
    # Serve assets from Cloud Storage
    dynamic "rewrite" {
      for_each = var.assets_paths
      content {
        glob = rewrite.value.glob
        run {
          service_id = "storage-api"
          region     = var.region
        }
      }
    }
  }
  
  depends_on = [google_storage_bucket.assets]
}

# Firebase Authentication configuration (opcional)
resource "google_firebase_project_location" "default" {
  count = var.configure_auth ? 1 : 0
  
  provider = google-beta
  project  = var.project_id
  location_id = var.firebase_location_id
}

resource "google_identity_platform_config" "auth" {
  count = var.configure_auth ? 1 : 0
  
  provider = google-beta
  project  = var.project_id
  
  autodelete_anonymous_users = var.autodelete_anonymous_users
  
  sign_in {
    allow_duplicate_emails = var.allow_duplicate_emails
    
    anonymous {
      enabled = var.enable_anonymous_auth
    }
    
    email {
      enabled           = var.enable_email_auth
      password_required = var.email_password_required
    }
  }
  
  depends_on = [google_firebase_project_location.default]
}

# Firebase Security Rules (opcional)
resource "google_firebaserules_ruleset" "firestore" {
  count = var.firestore_rules != null ? 1 : 0
  
  provider = google-beta
  project  = var.project_id
  
  source {
    files {
      name    = "firestore.rules"
      content = var.firestore_rules
    }
  }
}

resource "google_firebaserules_release" "firestore" {
  count = var.firestore_rules != null ? 1 : 0
  
  provider = google-beta
  project  = var.project_id
  name     = "cloud.firestore"
  ruleset_name = google_firebaserules_ruleset.firestore[0].name
}

resource "google_firebaserules_ruleset" "storage" {
  count = var.storage_rules != null ? 1 : 0
  
  provider = google-beta
  project  = var.project_id
  
  source {
    files {
      name    = "storage.rules"
      content = var.storage_rules
    }
  }
}

resource "google_firebaserules_release" "storage" {
  count = var.storage_rules != null ? 1 : 0
  
  provider = google-beta
  project  = var.project_id
  name     = "firebase.storage/${google_firebase_hosting_site.main.site_id}"
  ruleset_name = google_firebaserules_ruleset.storage[0].name
}

# Generate firebase-config.json for the React app
resource "local_file" "firebase_config" {
  count = var.generate_config_file ? 1 : 0
  
  filename = var.config_output_path != "" ? "${var.config_output_path}/firebase-config.json" : "${path.module}/../../frontend/public/firebase-config.json"
  
  content = jsonencode({
    apiKey = google_firebase_web_app_config.main.api_key
    authDomain = "${google_firebase_web_app.main.app_id}.firebaseapp.com"
    projectId = var.project_id
    storageBucket = var.create_assets_bucket ? google_storage_bucket.assets[0].name : "${var.project_id}.appspot.com"
    messagingSenderId = google_firebase_web_app_config.main.messaging_sender_id
    appId = google_firebase_web_app.main.app_id
    measurementId = google_firebase_web_app_config.main.measurement_id
    databaseURL = var.database_url != "" ? var.database_url : null
    environment = var.environment
    grafanaUrl = var.grafana_url
    apiUrl = var.api_url
  })
  
  depends_on = [
    google_firebase_web_app.main,
    google_firebase_web_app_config.main
  ]
}

# Firebase Hosting GitHub Actions secret (opcional)
resource "google_secret_manager_secret" "firebase_token" {
  count = var.create_github_secret ? 1 : 0
  
  secret_id = "firebase-token-${var.environment}"
  
  replication {
    auto {}
  }
  
  labels = merge(var.tags, {
    purpose = "github-actions"
  })
}

resource "google_secret_manager_secret_version" "firebase_token" {
  count = var.create_github_secret && var.firebase_token != "" ? 1 : 0
  
  secret = google_secret_manager_secret.firebase_token[0].id
  secret_data = var.firebase_token
}

# Create a service account for CI/CD
resource "google_service_account" "firebase_deploy" {
  count = var.create_deploy_sa ? 1 : 0
  
  account_id   = "firebase-deploy-${var.environment}"
  display_name = "Firebase Deploy Service Account - ${var.environment}"
  description  = "Service account for Firebase Hosting deployments"
  project      = var.project_id
}

# Grant necessary roles to the deploy service account
resource "google_project_iam_member" "firebase_deploy_roles" {
  for_each = var.create_deploy_sa ? toset([
    "roles/firebasehosting.admin",
    "roles/firebase.admin",
    "roles/iam.serviceAccountUser"
  ]) : []
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.firebase_deploy[0].email}"
}

# Generate firebase.json configuration file
resource "local_file" "firebase_json" {
  count = var.generate_firebase_json ? 1 : 0
  
  filename = var.firebase_json_output_path != "" ? "${var.firebase_json_output_path}/firebase.json" : "${path.module}/../../frontend/firebase.json"
  
  content = jsonencode({
    hosting = {
      public = var.build_output_dir
      ignore = [
        "firebase.json",
        "**/.*",
        "**/node_modules/**"
      ]
      rewrites = var.spa_routing ? [
        {
          source = "**"
          destination = "/index.html"
        }
      ] : var.rewrites
      redirects = var.redirects
      headers = [
        for glob, headers in var.security_headers_by_glob : {
          source = glob
          headers = [
            for key, value in headers : {
              key   = key
              value = value
            }
          ]
        }
      ]
      cleanUrls = var.clean_urls
      trailingSlashBehavior = var.trailing_slash_behavior
      appAssociation = "AUTO"
    }
  })
  
  depends_on = [google_firebase_hosting_site.main]
}

# Create a Cloud Function for SSR (opcional)
resource "google_cloudfunctions2_function" "ssr" {
  count = var.enable_ssr ? 1 : 0
  
  project     = var.project_id
  location    = var.region
  name        = "${replace(var.service_name, "-", "")}ssr"
  description = "SSR function for ${var.service_name}"
  
  build_config {
    runtime     = var.ssr_runtime
    entry_point = var.ssr_entry_point
    source {
      storage_source {
        bucket = var.ssr_source_bucket
        object = var.ssr_source_object
      }
    }
  }
  
  service_config {
    max_instance_count = var.ssr_max_instances
    min_instance_count = var.ssr_min_instances
    available_memory   = var.ssr_memory
    timeout_seconds    = var.ssr_timeout
    environment_variables = merge(var.ssr_env_vars, {
      FIREBASE_CONFIG = google_firebase_web_app_config.main.api_key
      GRAFANA_URL     = var.grafana_url
      API_URL         = var.api_url
    })
    ingress_settings = "ALLOW_ALL"
    all_traffic_on_latest_revision = true
    service_account_email = var.create_deploy_sa ? google_service_account.firebase_deploy[0].email : null
  }
  
  labels = merge(var.tags, {
    environment = var.environment
    type        = "ssr-function"
  })
  
  depends_on = [google_firebase_web_app.main]
}

# Update hosting config to use SSR function
resource "google_firebase_hosting_version" "ssr" {
  count = var.enable_ssr ? 1 : 0
  
  provider = google-beta
  project  = var.project_id
  site_id  = google_firebase_hosting_site.main.site_id
  
  config {
    rewrite {
      glob = var.ssr_route_pattern
      run {
        service_id = google_cloudfunctions2_function.ssr[0].function
        region     = var.region
      }
    }
    
    # Existing config from main version
    dynamic "rewrite" {
      for_each = var.spa_routing ? [1] : []
      content {
        glob = "**"
        path = "/index.html"
      }
    }
    
    dynamic "redirect" {
      for_each = var.redirects
      content {
        glob        = redirect.value.glob
        location    = redirect.value.location
        status_code = redirect.value.status_code
      }
    }
  }
  
  depends_on = [google_cloudfunctions2_function.ssr]
}

# Release for SSR version
resource "google_firebase_hosting_release" "ssr" {
  count = var.enable_ssr ? 1 : 0
  
  provider = google-beta
  project  = var.project_id
  site_id  = google_firebase_hosting_site.main.site_id
  version_name = google_firebase_hosting_version.ssr[0].id
  message  = "SSR Deploy ${var.environment} - ${formatdate("YYYY-MM-DD hh:mm:ss", timestamp())}"
  type     = "DEPLOY"
  
  depends_on = [google_firebase_hosting_version.ssr]
}