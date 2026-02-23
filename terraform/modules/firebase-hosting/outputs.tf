# Outputs principais
output "site_id" {
  description = "ID do site Firebase Hosting"
  value       = google_firebase_hosting_site.main.site_id
}

output "site_url" {
  description = "URL do site (padrão firebaseapp.com)"
  value       = "https://${google_firebase_hosting_site.main.site_id}.web.app"
}

output "site_default_url" {
  description = "URL padrão do site"
  value       = google_firebase_hosting_site.main.default_url
}

output "hosting_url" {
  description = "URL de hospedagem (apelido para site_url)"
  value       = "https://${google_firebase_hosting_site.main.site_id}.web.app"
}

output "app_id" {
  description = "ID do aplicativo Firebase"
  value       = google_firebase_web_app.main.app_id
}

output "app_display_name" {
  description = "Nome de exibição do aplicativo"
  value       = google_firebase_web_app.main.display_name
}

# Firebase Configuration
output "firebase_config" {
  description = "Configuração do Firebase para o frontend"
  value = {
    apiKey            = google_firebase_web_app_config.main.api_key
    authDomain        = "${google_firebase_web_app.main.app_id}.firebaseapp.com"
    projectId         = var.project_id
    storageBucket     = var.create_assets_bucket ? google_storage_bucket.assets[0].name : "${var.project_id}.appspot.com"
    messagingSenderId = google_firebase_web_app_config.main.messaging_sender_id
    appId             = google_firebase_web_app.main.app_id
    measurementId     = google_firebase_web_app_config.main.measurement_id
    environment       = var.environment
    grafanaUrl        = var.grafana_url
    apiUrl            = var.api_url
  }
  sensitive = false
}

output "api_key" {
  description = "API Key do Firebase"
  value       = google_firebase_web_app_config.main.api_key
  sensitive   = true
}

output "auth_domain" {
  description = "Auth domain do Firebase"
  value       = "${google_firebase_web_app.main.app_id}.firebaseapp.com"
}

output "messaging_sender_id" {
  description = "Messaging sender ID"
  value       = google_firebase_web_app_config.main.messaging_sender_id
}

output "measurement_id" {
  description = "Measurement ID do Google Analytics"
  value       = google_firebase_web_app_config.main.measurement_id
}

# Custom Domain
output "custom_domain" {
  description = "Domínio customizado (se configurado)"
  value       = try(google_firebase_hosting_custom_domain.main[0].custom_domain, null)
}

output "custom_domain_status" {
  description = "Status do domínio customizado"
  value       = try(google_firebase_hosting_custom_domain.main[0].domain_status, null)
}

output "custom_domain_certificate_status" {
  description = "Status do certificado SSL do domínio customizado"
  value       = try(google_firebase_hosting_custom_domain.main[0].cert_status, null)
}

# DNS Records for custom domain
output "dns_records" {
  description = "Registros DNS necessários para o domínio customizado"
  value = try(google_firebase_hosting_custom_domain.main[0].required_dns_updates, [])
}

# Preview Channel
output "preview_channel_url" {
  description = "URL do canal de preview"
  value       = try(google_firebase_hosting_channel.preview[0].channel_url, null)
}

output "dev_channel_url" {
  description = "URL do canal de desenvolvimento"
  value       = try(google_firebase_hosting_channel.dev[0].channel_url, null)
}

# Assets Bucket
output "assets_bucket_name" {
  description = "Nome do bucket de assets"
  value       = try(google_storage_bucket.assets[0].name, null)
}

output "assets_bucket_url" {
  description = "URL do bucket de assets"
  value       = try(google_storage_bucket.assets[0].url, null)
}

# Service Accounts
output "deploy_service_account_email" {
  description = "Email da service account de deploy"
  value       = try(google_service_account.firebase_deploy[0].email, null)
}

output "deploy_service_account_id" {
  description = "ID da service account de deploy"
  value       = try(google_service_account.firebase_deploy[0].unique_id, null)
}

# Secrets
output "firebase_token_secret_id" {
  description = "ID do secret do Firebase token"
  value       = try(google_secret_manager_secret.firebase_token[0].secret_id, null)
}

# SSR Function
output "ssr_function_name" {
  description = "Nome da função SSR"
  value       = try(google_cloudfunctions2_function.ssr[0].name, null)
}

output "ssr_function_url" {
  description = "URL da função SSR"
  value       = try(google_cloudfunctions2_function.ssr[0].service_config[0].uri, null)
}

# Generated Files
output "firebase_config_file" {
  description = "Caminho do arquivo de configuração gerado"
  value       = try(local_file.firebase_config[0].filename, null)
}

output "firebase_json_file" {
  description = "Caminho do firebase.json gerado"
  value       = try(local_file.firebase_json[0].filename, null)
}

# Release Info
output "latest_release" {
  description = "Informações da última release"
  value = {
    name    = google_firebase_hosting_release.main.name
    message = google_firebase_hosting_release.main.message
    type    = google_firebase_hosting_release.main.type
    version = google_firebase_hosting_release.main.version_name
  }
}

output "release_time" {
  description = "Timestamp da última release"
  value       = google_firebase_hosting_release.main.create_time
}

# Deployment info for CI/CD
output "deployment_info" {
  description = "Informações para deploy via CI/CD"
  value = {
    project_id     = var.project_id
    site_id        = google_firebase_hosting_site.main.site_id
    app_id         = google_firebase_web_app.main.app_id
    service_account = try(google_service_account.firebase_deploy[0].email, null)
    build_dir      = var.build_output_dir
    firebase_json  = try(local_file.firebase_json[0].filename, null)
  }
}

# Auth Configuration
output "auth_config" {
  description = "Configuração de autenticação"
  value = var.configure_auth ? {
    enabled               = true
    anonymous_enabled     = var.enable_anonymous_auth
    email_enabled         = var.enable_email_auth
    allow_duplicate_emails = var.allow_duplicate_emails
  } : null
}

# Security Rules
output "firestore_ruleset_name" {
  description = "Nome do ruleset do Firestore"
  value       = try(google_firebaserules_ruleset.firestore[0].name, null)
}

output "storage_ruleset_name" {
  description = "Nome do ruleset do Storage"
  value       = try(google_firebaserules_ruleset.storage[0].name, null)
}

# Terraform module info
output "module_info" {
  description = "Informações do módulo"
  value = {
    name        = "firebase-hosting"
    version     = "1.0"
    environment = var.environment
  }
}