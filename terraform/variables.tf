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

# variable "address_space" {
#   description = "The address space for the virtual network"
#   type        = string
#   default     = "10.0.0.0/16"
# }

variable "subscription_id" {
    type    = string
}

variable "vm_size" {
    type    = string
}

variable "vm_count" {
    type    = number
}

variable "address_space" {
    type    = string
    default = ""
}

variable "resource_groups" {
  type = map(string)
  default = {
    app    = "canadacentral"
    db     = "eastus"
    shared = "eastus2"
  }
}