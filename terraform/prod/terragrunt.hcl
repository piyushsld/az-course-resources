include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../"
}

inputs = {
  environment     = "prod"
  location        = "canadacentral"
  subscription_id = "99852d3c-e87c-4017-9a07-9c99dd605e1b"
  vm_size         = "Standard_B2s"
  vm_count        = 2
  address_space   = "10.0.2.0/16"
}
