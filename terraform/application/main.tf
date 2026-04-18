locals {
  location = var.region
}

resource "azurerm_resource_group" "rg2" {
  name     = local.rg_name
  location = var.region
}

resource "azurerm_user_assigned_identity" "rg1-id" {
  location            = var.region
  name                = "tf-id-demo"
  resource_group_name = local.rg_name
}

resource "azurerm_user_assigned_identity" "rg1-id2" {
  location            = var.region
  name                = "td-demo-id2"
  resource_group_name = local.rg_name
}

# /subscriptions/99852d3c-e87c-4017-9a07-9c99dd605e1b/resourceGroups/tf-demo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/td-demo-id2

data "azurerm_resource_group" "rg3" {
  name = "tf-demo2"
}

# resource "azurerm_user_assigned_identity" "rg1-id3" {
#   location            = var.region
#   name                = "td-demo-id3"
#   resource_group_name = data.azurerm_resource_group.rg3.name
# }

resource "azurerm_storage_account" "example" {
  count                             = var.create_stgaccnt ? 1 : 0
  name                              = "storageaccountname"
  resource_group_name               = local.rg_name
  location                          = var.region
  account_tier                      = var.account_tier
  account_replication_type          = "GRS"
  infrastructure_encryption_enabled = var.enable_encryption
  nfsv3_enabled                     = false
  min_tls_version                   = "TLS1_2"

  tags = var.tags
}

resource "azurerm_virtual_network" "example_vnet" {
  name                = "example-network"
  location            = var.region
  resource_group_name = local.rg_name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  dynamic "subnet" {
    for_each = var.subnet_cidrs
    content {
      name             = "subnet-${index(var.subnet_cidrs, subnet.value) + 1}"
      address_prefixes = [subnet.value]
    }
  }

  tags = var.tags
}