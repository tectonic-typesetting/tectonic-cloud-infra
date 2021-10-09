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

terraform {
  required_providers {
    azurerm = {
      version = "~> 2.80.0"
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
