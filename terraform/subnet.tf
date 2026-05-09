# module "subnet" {
#   source                = "./modules/subnet"
#   environment           = var.environment
#   subnet_name           = var.subnet_name
#   subnet_address_prefix = var.subnet_address_prefix
#   rg_name               = module.resource_group.rgname
#   vnet_name             = module.vnet.vnet_name
#   subnet_delegation     = local.subnet_delegation
# }

module "avm-res-network-virtualnetwork" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"

  address_space = ["10.0.0.0/16"]
  location      = "eastus2"
  name          = "vnet-demo-eastus2-001"
  parent_id     = "/subscriptions/${var.subscription_id}/resourceGroups/${var.rg_name}"
  subnets = {
    "subnet1" = {
      name             = "subnet1"
      address_prefixes = ["10.0.0.0/24"]
    }
    "subnet2" = {
      name             = "subnet2"
      address_prefixes = ["10.0.1.0/24"]
    }
  }
}