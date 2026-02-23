# Variáveis obrigatórias
variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "environment" {
  description = "Nome do ambiente (dev, stage, prod)"
  type        = string
}

variable "app_display_name" {
  description = "Nome de exibição do aplicativo Firebase"
  type        = string
  default     = "Contagem Acessos Frontend"
}

# Configuração do site
variable "site_id" {
  description = "ID do site Firebase Hosting (opcional - será gerado se vazio)"
  type        = string
  default     = ""
}

variable "service_name" {
  description = "Nome do serviço (para recursos relacionados)"
  type        = string
  default     = "frontend"
}

variable "region" {
  description = "Região do GCP para recursos adicionais"
  type        = string
  default     = "us-central1"
}

# Configuração do frontend
variable "build_output_dir" {
  description = "Diretório de saída do build (para firebase.json)"
  type        = string
  default     = "build"
}

variable "spa_routing" {
  description = "Habilitar roteamento SPA (redirecionar todas as rotas para index.html)"
  type        = bool
  default     = true
}

variable "clean_urls" {
  description = "Habilitar URLs limpas (remover .html)"
  type        = bool
  default     = true
}

variable "trailing_slash_behavior" {
  description = "Comportamento da barra no final da URL"
  type        = string
  default     = "ADD_TRAILING_SLASH"
  
  validation {
    condition     = contains(["ADD_TRAILING_SLASH", "REMOVE_TRAILING_SLASH", "NO_TRAILING_SLASH_BEHAVIOR"], var.trailing_slash_behavior)
    error_message = "Trailing slash behavior must be ADD_TRAILING_SLASH, REMOVE_TRAILING_SLASH, or NO_TRAILING_SLASH_BEHAVIOR."
  }
}

# Headers de segurança
variable "security_headers" {
  description = "Headers de segurança para o site"
  type = map(map(string))
  default = {
    "**" = {
      "X-Frame-Options" = "SAMEORIGIN"
      "X-Content-Type-Options" = "nosniff"
      "Referrer-Policy" = "strict-origin-when-cross-origin"
      "Permissions-Policy" = "geolocation=(), microphone=(), camera=()"
      "X-XSS-Protection" = "1; mode=block"
    }
    "*.js" = {
      "Cache-Control" = "public, max-age=31536000, immutable"
    }
    "*.css" = {
      "Cache-Control" = "public, max-age=31536000, immutable"
    }
    "*.png" = {
      "Cache-Control" = "public, max-age=31536000, immutable"
    }
    "*.jpg" = {
      "Cache-Control" = "public, max-age=31536000, immutable"
    }
    "*.svg" = {
      "Cache-Control" = "public, max-age=31536000, immutable"
    }
    "*.ico" = {
      "Cache-Control" = "public, max-age=31536000, immutable"
    }
    "*.woff2" = {
      "Cache-Control" = "public, max-age=31536000, immutable"
    }
  }
}

variable "security_headers_by_glob" {
  description = "Headers de segurança agrupados por glob (para firebase.json)"
  type = map(map(string))
  default = {
    "**" = {
      "X-Frame-Options" = "SAMEORIGIN"
      "X-Content-Type-Options" = "nosniff"
      "Referrer-Policy" = "strict-origin-when-cross-origin"
      "Permissions-Policy" = "geolocation=(), microphone=(), camera=()"
      "X-XSS-Protection" = "1; mode=block"
    }
  }
}

# Redirects
variable "redirects" {
  description = "Regras de redirecionamento"
  type = list(object({
    glob         = string
    location     = string
    status_code  = number
  }))
  default = []
}

# Rewrites customizados
variable "rewrites" {
  description = "Regras de rewrite customizadas (sobrescreve spa_routing)"
  type = list(object({
    source      = string
    destination = string
    type        = optional(string, "200")
  }))
  default = []
}

# URLs importantes
variable "grafana_url" {
  description = "URL do Grafana para o frontend"
  type        = string
  default     = ""
}

variable "api_url" {
  description = "URL da API backend"
  type        = string
  default     = ""
}

variable "database_url" {
  description = "URL do Firebase Realtime Database (opcional)"
  type        = string
  default     = ""
}

# Custom domain
variable "custom_domain" {
  description = "Domínio customizado para o site"
  type        = string
  default     = null
}

variable "wait_dns_verification" {
  description = "Aguardar verificação DNS para domínio customizado"
  type        = bool
  default     = false
}

# Preview channel
variable "create_preview_channel" {
  description = "Criar canal de preview"
  type        = bool
  default     = false
}

variable "preview_channel_ttl" {
  description = "TTL do canal de preview em segundos"
  type        = string
  default     = "86400s"  # 1 dia
}

# Asset storage
variable "create_assets_bucket" {
  description = "Criar bucket para assets estáticos"
  type        = bool
  default     = false
}

variable "assets_storage_class" {
  description = "Storage class para bucket de assets"
  type        = string
  default     = "STANDARD"
}

variable "assets_cors_origins" {
  description = "Origens permitidas para CORS no bucket de assets"
  type        = list(string)
  default     = ["*"]
}

variable "assets_versioning" {
  description = "Habilitar versionamento no bucket de assets"
  type        = bool
  default     = false
}

variable "assets_retention_days" {
  description = "Dias de retenção para assets (para lifecycle rules)"
  type        = number
  default     = 90
}

variable "assets_public_read" {
  description = "Tornar bucket de assets público"
  type        = bool
  default     = true
}

variable "assets_paths" {
  description = "Paths para servir assets do bucket"
  type = list(object({
    glob = string
  }))
  default = [
    {
      glob = "/assets/**"
    },
    {
      glob = "/static/**"
    }
  ]
}

# Firebase Authentication
variable "configure_auth" {
  description = "Configurar Firebase Authentication"
  type        = bool
  default     = false
}

variable "firebase_location_id" {
  description = "Localização do Firebase (para Auth)"
  type        = string
  default     = "us-central1"
}

variable "autodelete_anonymous_users" {
  description = "Auto-deletar usuários anônimos"
  type        = bool
  default     = false
}

variable "allow_duplicate_emails" {
  description = "Permitir emails duplicados"
  type        = bool
  default     = false
}

variable "enable_anonymous_auth" {
  description = "Habilitar autenticação anônima"
  type        = bool
  default     = false
}

variable "enable_email_auth" {
  description = "Habilitar autenticação por email/senha"
  type        = bool
  default     = true
}

variable "email_password_required" {
  description = "Exigir senha para autenticação por email"
  type        = bool
  default     = true
}

# Security Rules
variable "firestore_rules" {
  description = "Firestore security rules (conteúdo do arquivo)"
  type        = string
  default     = null
}

variable "storage_rules" {
  description = "Storage security rules (conteúdo do arquivo)"
  type        = string
  default     = null
}

# Config file generation
variable "generate_config_file" {
  description = "Gerar arquivo de configuração do Firebase"
  type        = bool
  default     = true
}

variable "config_output_path" {
  description = "Caminho para salvar o arquivo de configuração"
  type        = string
  default     = ""
}

variable "generate_firebase_json" {
  description = "Gerar arquivo firebase.json"
  type        = bool
  default     = true
}

variable "firebase_json_output_path" {
  description = "Caminho para salvar o firebase.json"
  type        = string
  default     = ""
}

# CI/CD
variable "create_github_secret" {
  description = "Criar secret no Secret Manager para GitHub Actions"
  type        = bool
  default     = false
}

variable "firebase_token" {
  description = "Token do Firebase para CI/CD (sensível)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "create_deploy_sa" {
  description = "Criar service account para deploy"
  type        = bool
  default     = true
}

# Server-Side Rendering (SSR) com Cloud Functions
variable "enable_ssr" {
  description = "Habilitar SSR com Cloud Functions"
  type        = bool
  default     = false
}

variable "ssr_runtime" {
  description = "Runtime da Cloud Function para SSR"
  type        = string
  default     = "nodejs20"
}

variable "ssr_entry_point" {
  description = "Entry point da função SSR"
  type        = string
  default     = "render"
}

variable "ssr_route_pattern" {
  description = "Padrão de rota para SSR"
  type        = string
  default     = "/**"
}

variable "ssr_source_bucket" {
  description = "Bucket com o código fonte da função SSR"
  type        = string
  default     = null
}

variable "ssr_source_object" {
  description = "Objeto com o código fonte da função SSR"
  type        = string
  default     = null
}

variable "ssr_max_instances" {
  description = "Máximo de instâncias para função SSR"
  type        = number
  default     = 10
}

variable "ssr_min_instances" {
  description = "Mínimo de instâncias para função SSR"
  type        = number
  default     = 0
}

variable "ssr_memory" {
  description = "Memória para função SSR"
  type        = string
  default     = "256Mi"
}

variable "ssr_timeout" {
  description = "Timeout para função SSR em segundos"
  type        = number
  default     = 60
}

variable "ssr_env_vars" {
  description = "Variáveis de ambiente para função SSR"
  type        = map(string)
  default     = {}
}

# Tags e labels
variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "contagem-acessos"
  }
}

# Configurações específicas por ambiente
variable "cache_control_max_age" {
  description = "Max-age para Cache-Control em segundos"
  type        = number
  default     = 31536000  # 1 ano
}

variable "cdn_cache_control" {
  description = "Configurações de cache para CDN"
  type = object({
    max_age       = number
    s_maxage      = number
    stale_while_revalidate = number
  })
  default = {
    max_age       = 3600
    s_maxage      = 3600
    stale_while_revalidate = 86400
  }
}

# Content Security Policy
variable "content_security_policy" {
  description = "Content Security Policy header"
  type        = string
  default     = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.firebaseapp.com https://*.web.app; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self' https://*.googleapis.com https://*.firebaseapp.com https://*.web.app https://*.grafana.net; frame-ancestors 'self' https://*.firebaseapp.com https://*.web.app;"
}

# Deployment strategy
variable "deployment_strategy" {
  description = "Estratégia de deploy (rolling, blue-green, canary)"
  type        = string
  default     = "rolling"
  
  validation {
    condition     = contains(["rolling", "blue-green", "canary"], var.deployment_strategy)
    error_message = "Deployment strategy must be rolling, blue-green, or canary."
  }
}