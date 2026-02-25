# Módulo Monitoring - Stack LGTM no AKS com LGPD
# Sanitização: OpenTelemetry Collector com transform processor
# Retenção: 90 dias (Loki, Tempo, Prometheus)
# Anonimização: User hash (SHA256) implementado na aplicação

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

# Namespace para Stack LGTM
resource "azurerm_kubernetes_cluster_namespace" "monitoring" {
  name                = "monitoring"
  kubernetes_cluster_id = var.aks_cluster_id
}

# Helm Release - OpenTelemetry Collector (Sanitização LGPD)
resource "helm_release" "otel_collector" {
  name       = "otel-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = "0.76.0"
  namespace  = "monitoring"

  values = [file("${path.module}/values/otel-collector-values.yaml")]

  depends_on = [azurerm_kubernetes_cluster_namespace.monitoring]
}

# Helm Release - Loki (Retenção 90 dias)
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "5.41.0"
  namespace  = "monitoring"

  values = [
    templatefile("${path.module}/values/loki-values.yaml", {
      storage_account_name = var.storage_account_name
      storage_account_key  = var.storage_account_key
      container_name       = var.loki_container_name
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
  namespace  = "monitoring"

  values = [
    templatefile("${path.module}/values/tempo-values.yaml", {
      storage_account_name = var.storage_account_name
      storage_account_key  = var.storage_account_key
      container_name       = var.tempo_container_name
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
  namespace  = "monitoring"

  values = [
    templatefile("${path.module}/values/prometheus-values.yaml", {
      storage_account_name = var.storage_account_name
      storage_account_key  = var.storage_account_key
      container_name       = var.prometheus_container_name
    })
  ]

  depends_on = [helm_release.otel_collector]
}

# Helm Release - Grafana (self-hosted no AKS)
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "7.0.0"
  namespace  = "monitoring"

  values = [file("${path.module}/values/grafana-values.yaml")]

  depends_on = [
    helm_release.loki,
    helm_release.tempo,
    helm_release.prometheus
  ]
}

# Service para expor Grafana
resource "azurerm_public_ip" "grafana" {
  name                = "pip-grafana-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}
