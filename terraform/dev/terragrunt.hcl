include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../"
    
  extra_arguments "vars" {
    commands = get_terraform_commands_that_need_vars()
    arguments = ["-var-file=dev.tfvars"]
  }
}

# inputs = {
#   environment     = "dev"
#   location        = "canadacentral"
#   subscription_id = "99852d3c-e87c-4017-9a07-9c99dd605e1b"
#   vm_size         = "Standard_B1s"
#   vm_count        = 1
#   address_space   = "10.0.0.0/16"
# }
