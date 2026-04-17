# Terraform — Dev Environment
#
# Usage:
#   cd infra/terraform/environments/dev
#   terraform init
#   terraform plan
#   terraform apply

terraform {
  required_version = ">= 1.5"

  # TODO: Configure your backend for remote state
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstateaccount"
  #   container_name       = "tfstate"
  #   key                  = "dev.terraform.tfstate"
  # }

  # backend "s3" {
  #   bucket = "my-terraform-state"
  #   key    = "dev/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# TODO: Configure your cloud provider
# provider "azurerm" {
#   features {}
# }
#
# provider "aws" {
#   region = var.region
# }

# TODO: Reference shared modules
# module "network" {
#   source      = "../../modules/network"
#   environment = "dev"
# }
#
# module "app" {
#   source      = "../../modules/app"
#   environment = "dev"
# }
