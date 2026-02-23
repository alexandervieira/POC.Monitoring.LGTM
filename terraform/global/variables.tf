variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "global"
}

variable "serverless_connector_cidr" {
  description = "CIDR ranges for serverless connectors per environment"
  type = map(string)
  default = {
    dev   = "10.8.0.0/28"
    stage = "10.8.1.0/28"
    prod  = "10.8.2.0/28"
  }
}

variable "create_dns_zone" {
  description = "Create DNS zone"
  type        = bool
  default     = false
}

variable "dns_name" {
  description = "DNS name for the zone"
  type        = string
  default     = "example.com."
}

variable "grafana_domains" {
  description = "Domains for Grafana certificates"
  type        = list(string)
  default = [
    "grafana-dev.example.com",
    "grafana-stage.example.com",
    "grafana.example.com"
  ]
}

variable "enable_cmek" {
  description = "Enable Customer Managed Encryption Keys"
  type        = bool
  default     = false
}

variable "create_monitoring_workspace" {
  description = "Create monitoring workspace"
  type        = bool
  default     = true
}

variable "enable_cost_alerts" {
  description = "Enable cost alerts"
  type        = bool
  default     = false
}

variable "cost_alert_threshold" {
  description = "Daily cost alert threshold in USD"
  type        = number
  default     = 100
}

variable "notification_channels" {
  description = "Notification channels for alerts"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Global tags"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "contagem-acessos"
  }
}