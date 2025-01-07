# Copyright the Tectonic Project
# Licensed under the MIT License

# The base resources of the "assets" domain. This isn't in the "permanent" tier
# but we don't expect to ever destroy these.

locals {
  pdataSubdomain = "data1"
}

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

resource "azurerm_cdn_frontdoor_profile" "assets" {
  name                = "${var.env}-fdassets"
  resource_group_name = azurerm_resource_group.assets_base.name
  sku_name            = "Standard_AzureFrontDoor"
}

# App Service Plan for various ... app services.

resource "azurerm_service_plan" "assets" {
  name                = "${var.env}-assets"
  location            = azurerm_resource_group.assets_base.location
  resource_group_name = azurerm_resource_group.assets_base.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# CDN details for `data1.fullyjustified.net` ("permanent data assets")

resource "azurerm_cdn_frontdoor_endpoint" "assets" {
  name                     = "${var.env}-fdassets"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.assets.id
}

resource "azurerm_cdn_frontdoor_origin_group" "assets" {
  name                     = "${var.env}-fdassets"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.assets.id

  load_balancing {}
}

resource "azurerm_cdn_frontdoor_origin" "pdata_assets" {
  name                           = "${var.env}-fdassets"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.assets.id
  enabled                        = true
  certificate_name_check_enabled = false
  host_name                      = azurerm_storage_account.permanent_data.primary_web_host
  origin_host_header             = azurerm_storage_account.permanent_data.primary_web_host
}

resource "azurerm_cdn_frontdoor_rule_set" "assets" {
  name                     = "rules"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.assets.id
}

resource "azurerm_cdn_frontdoor_route" "assets" {
  name                          = "${var.env}-fdassets"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.assets.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.assets.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.pdata_assets.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.assets.id]
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cache {}

  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.assets.id]
  link_to_default_domain          = true
}

resource "azurerm_cdn_frontdoor_custom_domain" "assets" {
  name                     = local.pdataSubdomain
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.assets.id
  dns_zone_id              = azurerm_dns_zone.assets.id
  host_name                = "${local.pdataSubdomain}.${azurerm_dns_zone.assets.name}"

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "assets" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.assets.id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.assets.id]
}

resource "azurerm_dns_txt_record" "assets" {
  name                = "_dnsauth.${local.pdataSubdomain}"
  zone_name           = azurerm_dns_zone.assets.name
  resource_group_name = azurerm_dns_zone.assets.resource_group_name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.assets.validation_token
  }
}

resource "azurerm_dns_cname_record" "assets" {
  depends_on = [azurerm_cdn_frontdoor_route.assets]

  name                = local.pdataSubdomain
  zone_name           = azurerm_dns_zone.assets.name
  resource_group_name = azurerm_dns_zone.assets.resource_group_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.assets.host_name
}
