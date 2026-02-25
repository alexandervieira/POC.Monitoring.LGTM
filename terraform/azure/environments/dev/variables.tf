variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}
