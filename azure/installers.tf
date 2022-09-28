# Copyright 2022 the Tectonic Project
# Licensed under the MIT License

# Infrastructure for installers.
#
# These (ab)use the relay app service to serve up redirects.

locals {
  dropShSubdomain  = "drop-sh"
  dropPs1Subdomain = "drop-ps1"
}

# The "drop-sh" subdomain

resource "azurerm_dns_cname_record" "drop_sh" {
  name                = local.dropShSubdomain
  zone_name           = azurerm_dns_zone.assets.name
  resource_group_name = azurerm_dns_zone.assets.resource_group_name
  ttl                 = 300
  record              = azurerm_linux_web_app.relay.default_hostname
}

resource "azurerm_dns_txt_record" "drop_sh_verify" {
  name                = "asuid.${local.dropShSubdomain}"
  zone_name           = azurerm_dns_zone.assets.name
  resource_group_name = azurerm_dns_zone.assets.resource_group_name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.relay.custom_domain_verification_id
  }
}

resource "azurerm_app_service_custom_hostname_binding" "drop_sh" {
  hostname            = "${local.dropShSubdomain}.${var.assetsDomain}"
  app_service_name    = azurerm_linux_web_app.relay.name
  resource_group_name = azurerm_resource_group.relay.name
  depends_on = [
    azurerm_dns_cname_record.drop_sh,
    azurerm_dns_txt_record.drop_sh_verify
  ]

  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }
}

resource "azurerm_app_service_managed_certificate" "drop_sh" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.drop_sh.id

  # https://github.com/hashicorp/terraform-provider-azurerm/issues/17883 :
  lifecycle {
    ignore_changes = [custom_hostname_binding_id]
  }
}

resource "azurerm_app_service_certificate_binding" "drop_sh" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.drop_sh.id
  certificate_id      = azurerm_app_service_managed_certificate.drop_sh.id
  ssl_state           = "SniEnabled"
}
