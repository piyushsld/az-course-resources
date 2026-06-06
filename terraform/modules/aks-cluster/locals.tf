locals {
  bootstrap_script = templatefile(
    "${path.module}/bootstrap.sh.tftpl",
    {
      github_runner_url   = var.gh_runner_url
      github_runner_token = var.gh_runner_token
      runner_name         = "ghrunner-01"
    }
  )

  cloud_init = templatefile(
    "${path.module}/cloud-init.yaml.tftpl",
    {
      bootstrap_script = local.bootstrap_script
    }
  )
}