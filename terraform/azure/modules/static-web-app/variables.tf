variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sku_tier" {
  type    = string
  default = "Free"
}

variable "sku_size" {
  type    = string
  default = "Free"
}

variable "custom_domain" {
  type    = string
  default = ""
}

variable "tags" {
  type = map(string)
}
