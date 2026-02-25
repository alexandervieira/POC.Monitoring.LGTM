variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "otel_endpoint" {
  type    = string
  default = "http://alloy.monitoring.svc.cluster.local:4317"
}

variable "db_connection_string" {
  type      = string
  sensitive = true
}

variable "tags" {
  type = map(string)
}
