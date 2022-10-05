# Copyright 2022 the Tectonic Project
# Licensed under the MIT License

# The "stacks" subdomain, for various static HTML reference documents.

locals {
  stacksSubdomain = "stacks"
}

resource "azurerm_cdn_endpoint" "stacks" {
  name                = "${var.env}-stacks"
  profile_name        = azurerm_cdn_profile.assets.name
  location            = azurerm_resource_group.assets_base.location
  resource_group_name = azurerm_resource_group.assets_base.name

  origin {
    name      = "pdata"
    host_name = azurerm_storage_account.permanent_data.primary_web_host
  }

  origin_host_header = azurerm_storage_account.permanent_data.primary_web_host
  origin_path        = "/_stacks"
}

resource "azurerm_dns_cname_record" "stacks" {
  name                = local.stacksSubdomain
  zone_name           = azurerm_dns_zone.assets.name
  resource_group_name = azurerm_dns_zone.assets.resource_group_name
  ttl                 = 3600
  target_resource_id  = azurerm_cdn_endpoint.stacks.id
}

resource "azurerm_cdn_endpoint_custom_domain" "stacks" {
  name            = local.stacksSubdomain
  cdn_endpoint_id = azurerm_cdn_endpoint.stacks.id
  host_name       = "${azurerm_dns_cname_record.stacks.name}.${azurerm_dns_zone.assets.name}"

  cdn_managed_https {
    certificate_type = "Shared"
    protocol_type    = "IPBased"
    tls_version      = "None"
  }

  depends_on = [
    azurerm_cdn_endpoint.stacks,
    azurerm_dns_cname_record.stacks
  ]
}
