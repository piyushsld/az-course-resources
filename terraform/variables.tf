variable "environment" {
  description = "The environment to deploy to (dev, prod)"
  type        = string
}

variable "location" {
  description = "The Azure region to deploy resources in"
  type        = string
}

variable "subscription_id" {
  type = string
}

variable "vnet_address_space" {
  type    = string
  default = ""
}

variable "rg_name" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "delegation_enabled" {
  description = "Whether to enable subnet delegation"
  type        = bool
}

variable "delegation_service_name" {
  description = "The name of the service to delegate to (e.g. Microsoft.ContainerInstance/containerGroups)"
  type        = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_address_prefix" {
  type = string
}

variable "client_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  sensitive   = true
}