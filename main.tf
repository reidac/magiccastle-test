terraform {
  required_version = ">= 1.5.7"
}

variable "pool" {
  description = "Slurm pool of compute nodes"
  default     = []
}

module "aws" {
  source         = "./aws"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "15.0.0"

  cluster_name = "cluster"
  domain       = "hpc-carpentry.cloud"
  # Rocky Linux 9.4 -  ca-central-1
  # https://rockylinux.org/download
  image = "ami-0c92b816e42b8f5ac" # Copied to US N Va zone.

  instances = {
    mgmt  = { type = "t3.large", count = 1, tags = ["mgmt", "puppet", "nfs"] },
    login = { type = "t3.medium", count = 1, tags = ["login", "public", "proxy"] },
    node  = { type = "t3.medium", count = 1, tags = ["node"] }
  }

  # var.pool is managed by Slurm through Terraform REST API.
  # To let Slurm manage a type of nodes, add "pool" to its tag list.
  # When using Terraform CLI, this parameter is ignored.
  # Refer to Magic Castle Documentation - Enable Magic Castle Autoscaling
  pool = var.pool

  volumes = {
    nfs = {
      home    = { size = 10, type = "gp2" }
      project = { size = 50, type = "gp2" }
      scratch = { size = 50, type = "gp2" }
    }
  }

  public_keys = [file("~/.ssh/Amazon1.pub")]

  nb_users = 10
  # Shared password, randomly chosen if blank
  guest_passwd = ""

  # AWS specifics
  region = "us-east-1"
}

output "accounts" {
  value = module.aws.accounts
}

output "public_ip" {
  value = module.aws.public_ip
}

## Uncomment to register your domain name with CloudFlare
module "dns"
  source           = "./dns/cloudflare"
  name             = module.aws.cluster_name
  domain           = module.aws.domain
  public_instances = module.aws.public_instances
}

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "./dns/gcloud"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.aws.cluster_name
#   domain           = module.aws.domain
#   public_instances = module.aws.public_instances
# }

# output "hostnames" {
# 	value = module.dns.hostnames
# }
