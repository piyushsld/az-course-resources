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

module "subnet" {
  source                = "./modules/subnet"
  environment           = var.environment
  rgname                = module.resource_group.rgname
  vnet_name             = module.vnet.vnetname
  subnet_name           = var.subnet_name
  subnet_address_prefix = var.subnet_address_prefix
  subnet_delegation     = local.subnet_delegation
}