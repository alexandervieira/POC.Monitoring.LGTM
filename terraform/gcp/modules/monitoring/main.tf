# Módulo Monitoring GCP - Stack LGTM no GKE com LGPD
# Sanitização: OpenTelemetry Collector com transform processor
# Retenção: 90 dias (Loki, Tempo, Prometheus)
# Storage: Google Cloud Storage

terraform {
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
}

# Namespace para Stack LGTM
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      environment = var.environment
      lgpd        = "enabled"
    }
  }
}

# Helm Release - OpenTelemetry Collector (Sanitização LGPD)
resource "helm_release" "otel_collector" {
  name       = "otel-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = "0.76.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [file("${path.module}/values/otel-collector-values.yaml")]
}

# Helm Release - Loki (Retenção 90 dias)
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "5.41.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    templatefile("${path.module}/values/loki-values.yaml", {
      gcs_bucket_name = var.loki_bucket_name
    })
  ]

  depends_on = [helm_release.otel_collector]
}

# Helm Release - Tempo (Retenção 90 dias)
resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  version    = "1.7.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    templatefile("${path.module}/values/tempo-values.yaml", {
      gcs_bucket_name = var.tempo_bucket_name
    })
  ]

  depends_on = [helm_release.otel_collector]
}

# Helm Release - Prometheus (Retenção 90 dias)
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.0.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    templatefile("${path.module}/values/prometheus-values.yaml", {
      gcs_bucket_name = var.prometheus_bucket_name
    })
  ]

  depends_on = [helm_release.otel_collector]
}

# Helm Release - Grafana (self-hosted no GKE)
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "7.0.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [file("${path.module}/values/grafana-values.yaml")]

  depends_on = [
    helm_release.loki,
    helm_release.tempo,
    helm_release.prometheus
  ]
}
