variable "environment" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "loki_bucket_name" {
  type = string
}

variable "tempo_bucket_name" {
  type = string
}

variable "prometheus_bucket_name" {
  type = string
}

variable "tags" {
  type = map(string)
}
