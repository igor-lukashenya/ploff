# Terraform — Production Environment

terraform {
  required_version = ">= 1.5"

  # TODO: Configure your backend for remote state
}

# TODO: Configure your cloud provider and reference shared modules
# module "network" {
#   source      = "../../modules/network"
#   environment = "production"
# }
