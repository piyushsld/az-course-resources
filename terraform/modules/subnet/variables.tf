variable "environment" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "rgname" {
  type = string
}

variable "subnet_address_prefix" {
  type = string
}

variable "vnet_name" {
  type = string
}

# variable "delegation_enabled" {
#   type    = bool
#   default = false
# }

# variable "delegation_service_name" {
#   type    = string
#   default = null
# }

variable "subnet_delegation" {
  type = object({
    name    = string
    service = string
    actions = list(string)
  })
  default = null
}