# Copyright 2021-2022 the Tectonic Project
# Licensed under the MIT License

# The "relay" URL redirection service. Relay URLs are embedded in distributed
# Tectonic binaries so we really want to make sure that they operate as reliably
# as possible.

locals {
  relaySubdomain = "relay"
}

resource "azurerm_resource_group" "relay" {
  name     = "tectonic-relay"
  location = var.location
  tags     = {}
}

# App service with managed TLS termination

resource "azurerm_linux_web_app" "relay" {
  name                = "${var.env}-relay"
  location            = azurerm_resource_group.relay.location
  resource_group_name = azurerm_resource_group.relay.name
  service_plan_id     = azurerm_service_plan.assets.id

  app_settings = {
    "DOCKER_ENABLE_CI"           = "true"
    "DOCKER_REGISTRY_SERVER_URL" = "https://index.docker.io/v1"
  }

  site_config {
    always_on         = true
    app_command_line  = ""
    use_32_bit_worker = false

    application_stack {
      docker_image_name = "tectonictypesetting/relay-service:latest"
    }
  }
}

resource "azurerm_dns_cname_record" "relay" {
  name                = local.relaySubdomain
  zone_name           = azurerm_dns_zone.assets.name
  resource_group_name = azurerm_dns_zone.assets.resource_group_name
  ttl                 = 300
  record              = azurerm_linux_web_app.relay.default_hostname
}

resource "azurerm_dns_txt_record" "relay" {
  name                = "asuid.${local.relaySubdomain}"
  zone_name           = azurerm_dns_zone.assets.name
  resource_group_name = azurerm_dns_zone.assets.resource_group_name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.relay.custom_domain_verification_id
  }
}

resource "azurerm_app_service_custom_hostname_binding" "relay" {
  hostname            = "${local.relaySubdomain}.${var.assetsDomain}"
  app_service_name    = azurerm_linux_web_app.relay.name
  resource_group_name = azurerm_resource_group.relay.name
  depends_on = [
    azurerm_dns_cname_record.relay,
    azurerm_dns_txt_record.relay
  ]

  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }
}

resource "azurerm_app_service_managed_certificate" "relay" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.relay.id

  # https://github.com/hashicorp/terraform-provider-azurerm/issues/17883 :
  lifecycle {
    ignore_changes = [custom_hostname_binding_id]
  }
}

resource "azurerm_app_service_certificate_binding" "relay" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.relay.id
  certificate_id      = azurerm_app_service_managed_certificate.relay.id
  ssl_state           = "SniEnabled"
}

# Relay also handles the toplevel assetsDomain traffic, so that we can associate
# an A record with it.

resource "azurerm_dns_a_record" "assets_root" {
  name                = "@"
  zone_name           = azurerm_dns_zone.assets.name
  resource_group_name = azurerm_dns_zone.assets.resource_group_name
  ttl                 = 300
  records             = [azurerm_linux_web_app.relay.outbound_ip_address_list[length(azurerm_linux_web_app.relay.outbound_ip_address_list) - 1]]
}

resource "azurerm_dns_txt_record" "assets_root" {
  name                = "asuid"
  zone_name           = azurerm_dns_zone.assets.name
  resource_group_name = azurerm_dns_zone.assets.resource_group_name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.relay.custom_domain_verification_id
  }
}

resource "azurerm_app_service_custom_hostname_binding" "assets_root" {
  hostname            = var.assetsDomain
  app_service_name    = azurerm_linux_web_app.relay.name
  resource_group_name = azurerm_resource_group.relay.name
  depends_on          = [azurerm_dns_txt_record.assets_root]

  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }
}

resource "azurerm_app_service_managed_certificate" "assets_root" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.assets_root.id

  # https://github.com/hashicorp/terraform-provider-azurerm/issues/17883 :
  lifecycle {
    ignore_changes = [custom_hostname_binding_id]
  }
}

resource "azurerm_app_service_certificate_binding" "assets_root" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.assets_root.id
  certificate_id      = azurerm_app_service_managed_certificate.assets_root.id
  ssl_state           = "SniEnabled"
}
