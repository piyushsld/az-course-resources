locals {
  subscriptions = {
    dev  = "99852d3c-e87c-4017-9a07-9c99dd605e1b"
    prod = "99852d3c-e87c-4017-9a07-9c99dd605e1b"
  }
}

provider "azurerm" {
  features {}
  # client_id       = ""
  # client_secret   = ""
  tenant_id       = "6ba9d606-3474-492c-9a99-c2c94ad5462f"
  subscription_id = local.subscriptions[terraform.workspace]
  use_cli         = true
}