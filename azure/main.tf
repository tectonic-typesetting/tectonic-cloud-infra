# Copyright the Tectonic Project
# Licensed under the MIT License

# Tectonic Azure resources. Terraform docs:
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
#
# Most of the action is in other files.
#
# To update the provider:
#
# - Remove `.terraform.lock.hcl`
# - Update minimum version here
# - Run `terraform init`
# - Run `terraform apply -var-file=prod.tfvars -refresh-only`

provider "azurerm" {
  subscription_id = "2f2d6506-e087-45f7-a59d-684b33a07485"

  features {}
}

terraform {
  required_providers {
    azurerm = {
      version = ">= 4.14.0"
    }
  }

  # Store state in our Azure blob storage:

  backend "azurerm" {
    resource_group_name  = "tectonic"
    storage_account_name = "ttassets"
    container_name       = "terraform-state"
    key                  = "prod.terraform.tfstate"
  }
}

# Base configuration properties of the active AzureRM setup:

data "azurerm_client_config" "current" {
}
