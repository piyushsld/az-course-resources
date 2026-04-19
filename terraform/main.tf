module "resource_group" {
  source      = "./modules/resource-group"
  environment = var.environment
  location    = var.location
  rg_name     = var.rg_name
}

module "vnet" {
  source             = "./modules/vnet"
  environment        = var.environment
  location           = var.location
  vnet_address_space = var.vnet_address_space
  rg_name            = module.resource_group.rgname
}
