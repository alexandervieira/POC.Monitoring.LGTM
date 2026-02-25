# Módulo Cloud Run para deploy da API .NET

# Data source para obter o projeto atual
data "google_project" "current" {}

# Resource: Cloud Run Service
resource "google_cloud_run_v2_service" "main" {
  name     = var.service_name
  location = var.region
  project  = var.project_id
  
  description = "API Contagem de Acessos - ${var.environment}"
  
  # Configuração do template
  template {
    # Anotações do container
    annotations = {
      # Cloud SQL connections
      "run.googleapis.com/cloudsql-instances" = join(",", var.cloud_sql_connections)
      
      # VPC Connector
      "run.googleapis.com/vpc-access-connector" = var.vpc_connector_enabled ? var.vpc_connector_name : null
      "run.googleapis.com/vpc-access-egress"    = var.vpc_connector_enabled ? "private-ranges-only" : null
      
      # Configurações de scaling
      "run.googleapis.com/startup-cpu-boost"    = var.enable_startup_cpu_boost ? "true" : "false"
      "run.googleapis.com/cpu-throttling"        = var.enable_cpu_throttling ? "true" : "false"
      
      # Health check
      "run.googleapis.com/health-check-enabled" = var.health_check_config.enabled ? "true" : "false"
    }
    
    # Labels
    labels = merge(var.tags, {
      environment = var.environment
      service     = var.service_name
    })
    
    # Configuração do container principal
    containers {
      name  = "api-${var.environment}"
      image = var.image
      
      # Recursos
      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle = var.min_instances == 0 ? true : false  # CPU idle quando scale to zero
      }
      
      # Porta do container
      ports {
        name           = "http1"
        container_port = var.container_port
      }
      
      # Comando de inicialização (opcional)
      dynamic "command" {
        for_each = var.startup_command != null ? [var.startup_command] : []
        content {
          command.value
        }
      }
      
      # Argumentos (opcional)
      dynamic "args" {
        for_each = var.startup_args != null ? [var.startup_args] : []
        content {
          args.value
        }
      }
      
      # Environment variables
      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }
      
      # Secrets (via environment variables)
      dynamic "env" {
        for_each = var.secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret_id
              version = env.value.version
            }
          }
        }
      }
      
      # Volume mounts (opcional)
      dynamic "volume_mounts" {
        for_each = var.volume_mounts
        content {
          name       = volume_mounts.value.name
          mount_path = volume_mounts.value.mount_path
        }
      }
      
      # Startup probe
      dynamic "startup_probe" {
        for_each = var.startup_probe_enabled ? [1] : []
        content {
          initial_delay_seconds = var.startup_probe_initial_delay
          timeout_seconds       = var.startup_probe_timeout
          period_seconds        = var.startup_probe_period
          failure_threshold     = var.startup_probe_failure_threshold
          
          dynamic "http_get" {
            for_each = var.startup_probe_http_path != null ? [1] : []
            content {
              path = var.startup_probe_http_path
              http_headers {
                name  = "User-Agent"
                value = "Cloud-Run-Startup-Probe"
              }
            }
          }
          
          dynamic "tcp_socket" {
            for_each = var.startup_probe_tcp_port != null ? [1] : []
            content {
              port = var.startup_probe_tcp_port
            }
          }
        }
      }
      
      # Liveness probe
      dynamic "liveness_probe" {
        for_each = var.liveness_probe_enabled ? [1] : []
        content {
          initial_delay_seconds = var.liveness_probe_initial_delay
          timeout_seconds       = var.liveness_probe_timeout
          period_seconds        = var.liveness_probe_period
          failure_threshold     = var.liveness_probe_failure_threshold
          
          dynamic "http_get" {
            for_each = var.liveness_probe_http_path != null ? [1] : []
            content {
              path = var.liveness_probe_http_path
              http_headers {
                name  = "User-Agent"
                value = "Cloud-Run-Liveness-Probe"
              }
            }
          }
        }
      }
    }
    
    # Volumes (opcional)
    dynamic "volumes" {
      for_each = var.volumes
      content {
        name = volumes.value.name
        
        dynamic "secret" {
          for_each = volumes.value.secret != null ? [volumes.value.secret] : []
          content {
            secret = secret.value.secret_name
            items {
              path = secret.value.path
              version = secret.value.version
              mode = secret.value.mode
            }
          }
        }
        
        dynamic "cloud_sql_instance" {
          for_each = volumes.value.cloud_sql_instance != null ? [volumes.value.cloud_sql_instance] : []
          content {
            instances = cloud_sql_instance.value.instances
          }
        }
      }
    }
    
    # Scaling
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }
    
    # Timeout
    timeout = var.request_timeout
    
    # Service account
    service_account = var.service_account_email
    
    # Execution environment
    execution_environment = var.execution_environment
    
    # Session affinity (opcional)
    session_affinity = var.session_affinity
    
    # Max concurrent requests
    max_instance_request_concurrency = var.concurrency
  }
  
  # Traffic splitting (para canary deployments)
  dynamic "traffic" {
    for_each = var.traffic_splits
    content {
      type        = traffic.value.type
      percent     = traffic.value.percent
      revision    = traffic.value.revision
      tag         = traffic.value.tag
    }
  }
  
  # Client information
  client = var.client_name
  client_version = var.client_version
  
  # Dependências
  depends_on = [
    var.module_depends_on
  ]
}

# IAM Policy - Permissões de acesso público (opcional)
resource "google_cloud_run_v2_service_iam_binding" "public_invoker" {
  count = var.public_access ? 1 : 0
  
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.main.name
  role     = "roles/run.invoker"
  members  = var.invoker_members
}

# IAM Policy - Permissões específicas por membro
resource "google_cloud_run_v2_service_iam_member" "invokers" {
  for_each = var.invoker_members_map
  
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.main.name
  role     = each.value.role
  member   = each.value.member
}

# Domain mapping (opcional)
resource "google_cloud_run_v2_service_domain_mapping" "custom_domain" {
  count = var.custom_domain != null ? 1 : 0
  
  project  = var.project_id
  location = var.region
  name     = var.custom_domain
  
  service {
    service = google_cloud_run_v2_service.main.name
  }
}

# Cloud Scheduler job para manter a API aquecida (opcional)
resource "google_cloud_scheduler_job" "keep_warm" {
  count = var.keep_warm_enabled ? 1 : 0
  
  project    = var.project_id
  region     = var.region
  name       = "${var.service_name}-keep-warm"
  description = "Keep API warm to reduce cold starts"
  schedule   = var.keep_warm_schedule
  
  http_target {
    http_method = "GET"
    uri         = "${google_cloud_run_v2_service.main.uri}/health"
    
    headers = {
      "User-Agent" = "Cloud-Scheduler-KeepWarm"
    }
    
    oidc_token {
      service_account_email = var.keep_warm_sa_email != null ? var.keep_warm_sa_email : google_service_account.keep_warm[0].email
    }
  }
  
  attempt_deadline = "60s"
  
  depends_on = [
    google_cloud_run_v2_service.main
  ]
}

# Service account para keep-warm
resource "google_service_account" "keep_warm" {
  count = var.keep_warm_enabled && var.keep_warm_sa_email == null ? 1 : 0
  
  account_id   = "${replace(var.service_name, "-", "")}keepwarm"
  display_name = "Keep Warm SA for ${var.service_name}"
  project      = var.project_id
}

# Permissão para o keep-warm invocar o serviço
resource "google_cloud_run_v2_service_iam_member" "keep_warm_invoker" {
  count = var.keep_warm_enabled ? 1 : 0
  
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.main.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.keep_warm_sa_email != null ? var.keep_warm_sa_email : google_service_account.keep_warm[0].email}"
}

# Log-based metrics (opcional)
resource "google_logging_metric" "request_count" {
  count = var.create_metrics ? 1 : 0
  
  project = var.project_id
  name    = "${replace(var.service_name, "-", "_")}_request_count"
  
  filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.service_name}\" AND httpRequest IS NOT NULL"
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    labels {
      key         = "response_code_class"
      value_type  = "STRING"
      description = "HTTP response code class (2xx, 3xx, 4xx, 5xx)"
    }
    labels {
      key         = "method"
      value_type  = "STRING"
      description = "HTTP method"
    }
    labels {
      key         = "endpoint"
      value_type  = "STRING"
      description = "Request endpoint path"
    }
  }
  
  label_extractors = {
    "response_code_class" = "EXTRACT(httpRequest.status / 100)"
    "method"              = "EXTRACT(httpRequest.requestMethod)"
    "endpoint"            = "REGEXP_EXTRACT(httpRequest.requestUrl, \"^https?://[^/]+(/[^?#]*)\")"
  }
}

# SLO Monitoring (opcional)
resource "google_monitoring_slo" "availability" {
  count = var.create_slo ? 1 : 0
  
  project      = var.project_id
  service      = var.slo_service_id
  slo_id       = "${var.service_name}-availability"
  display_name = "Availability SLO for ${var.service_name}"
  goal         = var.slo_availability_goal
  calendar_period = var.slo_calendar_period
  
  request_based_sli {
    distribution_cut {
      distribution_filter = "metric.type=\"run.googleapis.com/request_count\" AND resource.labels.service_name=\"${var.service_name}\" AND metric.labels.response_code_class=\"200\""
      range {
        max = 1
      }
    }
  }
}

resource "google_monitoring_slo" "latency" {
  count = var.create_slo ? 1 : 0
  
  project      = var.project_id
  service      = var.slo_service_id
  slo_id       = "${var.service_name}-latency"
  display_name = "Latency SLO for ${var.service_name}"
  goal         = var.slo_latency_goal
  calendar_period = var.slo_calendar_period
  
  request_based_sli {
    distribution_cut {
      distribution_filter = "metric.type=\"run.googleapis.com/request_latencies\" AND resource.labels.service_name=\"${var.service_name}\""
      range {
        max = var.slo_latency_threshold_ms / 1000  # Converter ms para segundos
      }
    }
  }
}