# terraform {
#   required_version = ">= 1.5.0"

#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = ">= 3.102.0"
#     }
#   }
# }

# provider "azurerm" {
#   features {}
# }

resource "azurerm_user_assigned_identity" "aks" {
  name                = "uami-aks-prod-uksouth-01"
  location            = "uksouth"
  resource_group_name = module.aks-rg.rgname
}

module "aks-rg" {
  source      = "./modules/resource-group"
  environment = var.environment
  location    = "uksouth"
  rg_name     = "rg-aks-prod-uksouth-01"
}

# resource "azurerm_resource_group" "rg" {
#   name     = "rg-aks-prod-uksouth-01"
#   location = "uksouth"
# }

module "aks_private" {
  source = "./modules/aks-cluster"

  resource_group_name       = module.aks-rg.rgname
  location                  = "uksouth"
  cluster_name              = "aks-prod-uksouth-01"
  dns_prefix                = "aksproduks01"
  identity_type             = "UserAssigned"
  user_assigned_identity_id = azurerm_user_assigned_identity.aks.id

  sku_tier                            = "Standard"
  private_cluster_enabled             = true
  api_server_vnet_integration_enabled = true

  vnet_name                  = "vnet-aks-prod-uksouth-01"
  vnet_address_space         = ["10.50.0.0/16"]
  node_subnet_name           = "snet-aks-nodes"
  node_subnet_prefixes       = ["10.50.1.0/24"]
  create_api_server_subnet   = true
  api_server_subnet_name     = "snet-aks-apiserver"
  api_server_subnet_prefixes = ["10.50.2.0/28"]

  system_pool_vm_size   = "Standard_D2ps_v6"
  system_pool_min_count = 2
  system_pool_max_count = 5

  user_pool_vm_size   = "Standard_D2ps_v6"
  user_pool_min_count = 2
  user_pool_max_count = 5

  tags = {
    env      = "prod"
    workload = "aks"
    tier     = "standard"
    region   = "uksouth"
  }
}

data "azurerm_client_config" "current" {}

# Get your user Object ID (replace with actual ID or use data source)
locals {
  user_object_id = "e94af094-451c-4943-ba57-feedf4cd5955" # Replace with your actual Object ID 
  # Run this to get your Object ID: az ad signed-in-user show --query id --output tsv
}

resource "azurerm_role_assignment" "aks_cluster_admin" {
  for_each = toset(([
    "Azure Kubernetes Service Cluster Admin Role",
    "Azure Kubernetes Service RBAC Cluster Admin"
  ]))
  scope                = module.aks_private.aks_id
  role_definition_name = each.key
  principal_id         = local.user_object_id
}