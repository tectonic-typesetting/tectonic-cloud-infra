# Copyright 2021 Peter Williams and collaborators
# Licensed under the MIT License

# The base resources of the "assets" domain. This isn't in the "permanent" tier
# but we don't expect to ever destroy these.

resource "azurerm_resource_group" "assets_base" {
  name     = "tectonic-assets-base"
  location = var.location
  tags     = {}
}

# DNS base

resource "azurerm_dns_zone" "assets" {
  name                = var.assetsDomain
  resource_group_name = azurerm_resource_group.assets_base.name
  tags                = {}
}

# CDN base

resource "azurerm_cdn_profile" "assets" {
  name                = "${var.env}-assets"
  location            = var.location
  resource_group_name = azurerm_resource_group.assets_base.name
  sku                 = "Standard_Verizon"
}

# CDN endpoint to make the permanent-data storage account available under a
# custom domain

resource "azurerm_cdn_endpoint" "pdata_assets" {
  name                = "${var.env}-pdata"
  profile_name        = azurerm_cdn_profile.assets.name
  location            = azurerm_resource_group.assets_base.location
  resource_group_name = azurerm_resource_group.assets_base.name

  origin {
    name      = "pdata1"
    host_name = azurerm_storage_account.permanent_data.primary_blob_host
  }
}

resource "azurerm_dns_cname_record" "pdata_assets" {
  name                = "data1"
  zone_name           = azurerm_dns_zone.assets.name
  resource_group_name = azurerm_dns_zone.assets.resource_group_name
  ttl                 = 3600
  target_resource_id  = azurerm_cdn_endpoint.pdata_assets.id
}

resource "azurerm_cdn_endpoint_custom_domain" "pdata_assets" {
  # Note: if creating everything from scratch, may need to re-attempt creation
  # of this resource because Azure needs the CNAME to already exist.
  name            = "pdata"
  cdn_endpoint_id = azurerm_cdn_endpoint.pdata_assets.id
  host_name       = "${azurerm_dns_cname_record.pdata_assets.name}.${azurerm_dns_zone.assets.name}"
}
