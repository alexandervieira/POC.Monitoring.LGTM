# Módulo Terraform - Firebase Hosting

Módulo para deploy de aplicações React no Firebase Hosting com configurações completas de segurança, SSR, e integração com outros serviços GCP.

## Características

- ✅ Deploy de Single Page Applications (React)
- ✅ Configuração automática de headers de segurança
- ✅ Suporte a domínios customizados com SSL automático
- ✅ Canais de preview para PRs
- ✅ Bucket separado para assets estáticos (opcional)
- ✅ Server-Side Rendering (SSR) com Cloud Functions
- ✅ Firebase Authentication configurável
- ✅ Security Rules para Firestore e Storage
- ✅ Geração automática de firebase-config.json
- ✅ Service account para CI/CD
- ✅ Headers de cache otimizados para assets estáticos

## Uso Básico

```hcl
module "firebase_hosting" {
  source = "../../modules/firebase-hosting"
  
  project_id   = var.project_id
  environment  = var.environment
  app_display_name = "Contagem Acessos - ${var.environment}"
  
  # URLs importantes
  grafana_url = "https://grafana-${var.environment}.example.com"
  api_url     = module.cloud_run.service_url
  
  # Configuração SPA
  spa_routing = true
  clean_urls  = true
  
  # Headers de segurança
  security_headers = {
    "**" = {
      "X-Frame-Options" = "SAMEORIGIN"
      "X-Content-Type-Options" = "nosniff"
      "Referrer-Policy" = "strict-origin-when-cross-origin"
      "Content-Security-Policy" = "frame-ancestors 'self' https://*.firebaseapp.com https://*.web.app;"
    }
  }
  
  # Domínio customizado (opcional)
  custom_domain = var.environment == "prod" ? "app.example.com" : null
  
  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}