locals {
  tenant_id = "6ba9d606-3474-492c-9a99-c2c94ad5462f"
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.14.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.69.0"
    }
  }
}
EOF
}

remote_state {
  backend = "azurerm"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    resource_group_name  = "tf-demo2"
    storage_account_name = "lddevopsstgaccnt01"
    container_name       = "tf-modules"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  features {}
  tenant_id       = "${local.tenant_id}"
  subscription_id = var.subscription_id
  use_cli         = true
}
EOF
}
