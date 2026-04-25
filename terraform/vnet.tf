# module "vnet" {
#   source             = "./modules/vnet"
#   environment        = var.environment
#   location           = var.location
#   vnet_address_space = var.vnet_address_space
#   rg_name            = module.resource_group.rgname
#   vnet_name          = var.vnet_name
# }

module "vnet2" {
  source             = "git::https://github.com/piyushsld/az-modules.git//modules/vnet?ref=v1.0.0"
  environment        = var.environment
  location           = var.location
  vnet_address_space = var.vnet_address_space
  rg_name            = module.resource_group_new.rgname
  vnet_name          = "vnet-new"
}