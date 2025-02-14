# Copyright the Tectonic Project
# Licensed under the MIT License

# The "stacks" subdomain, for various static HTML reference documents.

locals {
  stacksSubdomain = "stacks"
}

resource "azurerm_cdn_frontdoor_endpoint" "stacks" {
  name                     = "${var.env}-fdstacks"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.assets.id
}

resource "azurerm_cdn_frontdoor_origin_group" "stacks" {
  name                     = "${var.env}-fdstacks"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.assets.id

  load_balancing {}
}

resource "azurerm_cdn_frontdoor_origin" "pdata_stacks" {
  name                           = "${var.env}-fdstacks"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.stacks.id
  enabled                        = true
  certificate_name_check_enabled = false
  host_name                      = azurerm_storage_account.permanent_data.primary_web_host
  origin_host_header             = azurerm_storage_account.permanent_data.primary_web_host
}

resource "azurerm_cdn_frontdoor_rule_set" "stacks" {
  name                     = "stacksRules"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.assets.id
}

resource "azurerm_cdn_frontdoor_rule" "stacks" {
  depends_on = [azurerm_cdn_frontdoor_origin_group.stacks, azurerm_cdn_frontdoor_origin.pdata_stacks]

  name                      = "subdir"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.stacks.id
  order                     = 1
  behavior_on_match         = "Stop"

  actions {
    url_rewrite_action {
      source_pattern          = "/"
      destination             = "/_stacks/"
      preserve_unmatched_path = true
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "stacks" {
  name                          = "${var.env}-fdstacks"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.stacks.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.stacks.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.pdata_stacks.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.stacks.id]
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cache {}

  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.stacks.id]
  link_to_default_domain          = true
}

resource "azurerm_cdn_frontdoor_custom_domain" "stacks" {
  name                     = local.stacksSubdomain
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.assets.id
  dns_zone_id              = azurerm_dns_zone.assets.id
  host_name                = "${local.stacksSubdomain}.${azurerm_dns_zone.assets.name}"

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "stacks" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.stacks.id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.stacks.id]
}

resource "azurerm_dns_txt_record" "fdstacks" {
  name                = "_dnsauth.${local.stacksSubdomain}"
  zone_name           = azurerm_dns_zone.assets.name
  resource_group_name = azurerm_dns_zone.assets.resource_group_name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.stacks.validation_token
  }
}

resource "azurerm_dns_cname_record" "fdstacks" {
  depends_on = [azurerm_cdn_frontdoor_route.stacks]

  name                = local.stacksSubdomain
  zone_name           = azurerm_dns_zone.assets.name
  resource_group_name = azurerm_dns_zone.assets.resource_group_name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.stacks.host_name
}
