variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "aks_cluster_id" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "storage_account_key" {
  type      = string
  sensitive = true
}

variable "loki_container_name" {
  type = string
}

variable "tempo_container_name" {
  type = string
}

variable "prometheus_container_name" {
  type = string
}

variable "tags" {
  type = map(string)
}
