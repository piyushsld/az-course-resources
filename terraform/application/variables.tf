variable "environment" {
  description = "The environment to deploy to (dev, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "The Azure region to deploy resources in"
  type        = string
  default     = "canadacentral"
}

variable "address_space" {
  description = "The address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}