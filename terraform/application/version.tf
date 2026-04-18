terraform {
  required_version = ">= 1.14.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.68.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tf-demo2"
    storage_account_name = "lddevopsstgaccnt01"
    container_name       = "tfstatestorage"
    key                  = "tfstate_demo"
  }
}