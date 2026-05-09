variable "subnet_name" {
  description = "The name of the subnet to create"
  type        = string
}

variable "environment" {
  description = "The environment to deploy to (dev, prod)"
  type        = string
}

variable "rg_name" {
  description = "The name of the resource group to create"
  type        = string
}

variable "vnet_name" {
  description = "The name of the virtual network to create"
  type        = string
}

variable "subnet_address_prefix" {
  description = "The address prefix for the subnet"
  type        = string
}

variable "subnet_delegation" {
  type = object({
    name    = string
    service = string
    actions = list(string)
  })
  default = null
}