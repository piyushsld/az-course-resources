variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "vnet_address_space" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "delegation_enabled" {
  type    = bool
  default = false
}

variable "delegation_service_name" {
  type    = string
  default = null
}

variable "subnet_name" {
  type = string
}

variable "subnet_address_prefix" {
  type = string
}