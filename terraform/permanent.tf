# Copyright 2021 Peter Williams and collaborators
# Licensed under the MIT License

# Terraform definitions of Tectonic's permanent data resources. These mostly exist so
# that other more actively evolving resources can reference them.

resource "azurerm_resource_group" "permanent" {
  name     = "tectonic"
  location = var.location

  lifecycle {
    prevent_destroy = true
  }
}

# Core, permanent storage account

resource "azurerm_storage_account" "permanent_data" {
  name                = var.permanentDataName
  resource_group_name = azurerm_resource_group.permanent.name
  location            = azurerm_resource_group.permanent.location

  account_tier              = "Standard"
  account_replication_type  = "RAGRS"
  allow_blob_public_access  = true
  enable_https_traffic_only = false
  min_tls_version           = "TLS1_2"

  static_website {
    error_404_document = "404.html"
    index_document     = "index.html"
  }

  lifecycle {
    prevent_destroy = true
  }
}
