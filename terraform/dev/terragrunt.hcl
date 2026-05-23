include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../"

  extra_arguments "vars" {
    commands  = get_terraform_commands_that_need_vars()
    arguments = ["-var-file=dev.tfvars"]
  }
  before_hook "copy_parent_tf" {
    commands = ["init"]
    execute = [
      "bash", "-c",
      "cp ${get_parent_terragrunt_dir()}/*.tf .terragrunt-cache/ 2>/dev/null || true"
    ]
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

# inputs = {
#   environment     = "dev"
#   location        = "canadacentral"
#   subscription_id = "99852d3c-e87c-4017-9a07-9c99dd605e1b"
#   vm_size         = "Standard_B1s"
#   vm_count        = 1
#   address_space   = "10.0.0.0/16"
# }
