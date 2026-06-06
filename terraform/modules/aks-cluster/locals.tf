locals {
  bootstrap_script = templatefile(
    "${path.module}/bootstrap.sh.tftpl",
    {
      github_runner_url   = var.gh_runner_url
      github_runner_token = var.gh_runner_token
      runner_name         = "ghrunner-01"
    }
  )

  cloud_init = <<-EOT
#cloud-config
${yamlencode({
  write_files = [
    {
      path        = "/home/azureuser/bootstrap.sh"
      permissions = "0755"
      owner       = "azureuser:azureuser"
      content     = local.bootstrap_script
    }
  ]

  runcmd = [
    "sudo -u azureuser bash /home/azureuser/bootstrap.sh"
  ]
})}
EOT
}