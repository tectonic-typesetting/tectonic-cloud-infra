# Copyright 2021 Peter Williams and collaborators
# Licensed under the MIT License

# Tectonic Azure resources. Terraform docs:
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
#
# Most of the action is in other files.

provider "azurerm" {
  features {}
}

# Store state in WWT's Azure blob storage:

terraform {
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
