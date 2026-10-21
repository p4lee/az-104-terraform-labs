module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags = {
    project = "az-104-portfolio"
    domain  = "app-service"
  }
}

# S1 (Standard) rather than F1/B1: deployment slots, autoscale rules and
# backup all require Standard or higher. This is the main cost in the
# exercise, so it is deployed, demonstrated and destroyed the same day.
resource "azurerm_service_plan" "this" {
  name                = "asp-az104-web"
  resource_group_name = module.resource_group.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name

  tags = {
    project = "az-104-portfolio"
    domain  = "app-service"
  }
}

resource "azurerm_linux_web_app" "this" {
  name                = var.app_name
  resource_group_name = module.resource_group.name
  location            = azurerm_service_plan.this.location
  service_plan_id     = azurerm_service_plan.this.id

  https_only = true

  site_config {
    # always_on keeps the app warm. Available from Basic upwards; on Free
    # and Shared the app unloads after idling.
    always_on = true

    # PHP is used only because its container serves static files from
    # /home/site/wwwroot with no build step - the point here is App Service
    # itself, not the runtime.
    application_stack {
      php_version = "8.2"
    }
  }

  tags = {
    project = "az-104-portfolio"
    domain  = "app-service"
  }

  # The backup schedule is configured by hand in the portal, because App
  # Service backup needs a storage SAS token and generating one here would
  # write a credential into the state file. Without this, every apply would
  # see the portal-configured backup as drift and remove it.
  lifecycle {
    ignore_changes = [backup]
  }
}

# A deployment slot is a second, complete copy of the app on the same plan.
# Deploy to it, check it, then swap - the swap exchanges the running
# instances rather than redeploying, so it is near-instant and reversible.
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.this.id

  https_only = true

  site_config {
    always_on = true

    application_stack {
      php_version = "8.2"
    }
  }

  tags = {
    project = "az-104-portfolio"
    domain  = "app-service"
  }
}

# Autoscale targets the PLAN, not the app: instances are plan-level, and
# every app and slot on the plan shares them. That is also why the staging
# slot costs nothing extra while it shares this plan.
resource "azurerm_monitor_autoscale_setting" "this" {
  name                = "asp-az104-web-autoscale"
  resource_group_name = module.resource_group.name
  location            = var.location
  target_resource_id  = azurerm_service_plan.this.id

  profile {
    name = "cpu-based"

    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

# Storage for App Service backups. The backup schedule itself is configured
# by hand in the portal: App Service needs a SAS token for the container,
# and generating one in Terraform would write a credential into the state
# file and re-create it on every expiry. Terraform owns the container; the
# short-lived credential stays out of it.
resource "azurerm_storage_account" "backup" {
  name                     = var.backup_storage_account_name
  resource_group_name      = module.resource_group.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = {
    project = "az-104-portfolio"
    domain  = "app-service"
  }
}

resource "azurerm_storage_container" "backup" {
  name                  = "appservice-backups"
  storage_account_name  = azurerm_storage_account.backup.name
  container_access_type = "private"
}

# ---------------------------------------------------------------------------
# Phase 2 - custom domain and TLS. All of this is gated on
# enable_custom_domain, because the apex A record needs the app's inbound IP,
# which doesn't exist until the app does.
# ---------------------------------------------------------------------------

# Exercise 04 owns the DNS zone; this exercise only adds records to it.
data "terraform_remote_state" "networking" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = "tfstate"
    key                  = "04-networking.tfstate"
  }
}

locals {
  enabled   = var.enable_custom_domain ? 1 : 0
  zone_name = data.terraform_remote_state.networking.outputs.dns_zone_name
  zone_rg   = data.terraform_remote_state.networking.outputs.dns_zone_resource_group
  apex_host = local.zone_name
  www_host  = "${var.subdomain}.${local.zone_name}"
}

# Apex: an A record pointing at the app's inbound IP. The zone root can't be
# a CNAME (DNS forbids CNAME alongside the SOA and NS records that live
# there), and Azure DNS alias records don't target App Service - hence an IP
# supplied by hand. That IP belongs to a shared App Service front end, not to
# this app, which is why the TXT record below is needed to prove ownership.
resource "azurerm_dns_a_record" "apex" {
  count               = local.enabled
  name                = "@"
  zone_name           = local.zone_name
  resource_group_name = local.zone_rg
  ttl                 = 300
  records             = [var.app_inbound_ip]
}

# Subdomain: a CNAME to the default hostname. No IP to track, so it survives
# the app moving to a different scale unit.
resource "azurerm_dns_cname_record" "www" {
  count               = local.enabled
  name                = var.subdomain
  zone_name           = local.zone_name
  resource_group_name = local.zone_rg
  ttl                 = 300
  record              = azurerm_linux_web_app.this.default_hostname
}

# asuid TXT records prove control of the name before App Service will bind
# it: "asuid" for the apex, "asuid.<subdomain>" for the subdomain.
resource "azurerm_dns_txt_record" "apex_verify" {
  count               = local.enabled
  name                = "asuid"
  zone_name           = local.zone_name
  resource_group_name = local.zone_rg
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.this.custom_domain_verification_id
  }
}

resource "azurerm_dns_txt_record" "www_verify" {
  count               = local.enabled
  name                = "asuid.${var.subdomain}"
  zone_name           = local.zone_name
  resource_group_name = local.zone_rg
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.this.custom_domain_verification_id
  }
}

# Binding the hostname makes App Service answer for it - over HTTP only
# until a certificate is bound below.
resource "azurerm_app_service_custom_hostname_binding" "apex" {
  count               = local.enabled
  hostname            = local.apex_host
  app_service_name    = azurerm_linux_web_app.this.name
  resource_group_name = module.resource_group.name

  depends_on = [
    azurerm_dns_a_record.apex,
    azurerm_dns_txt_record.apex_verify,
  ]

  # ssl_state and thumbprint are set by the certificate binding below.
  # Without this, every apply would try to reset them to "no certificate".
  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }
}

resource "azurerm_app_service_custom_hostname_binding" "www" {
  count               = local.enabled
  hostname            = local.www_host
  app_service_name    = azurerm_linux_web_app.this.name
  resource_group_name = module.resource_group.name

  depends_on = [
    azurerm_dns_cname_record.www,
    azurerm_dns_txt_record.www_verify,
  ]

  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }
}

# App Service managed certificates: free, issued and renewed by Azure. They
# require the hostname to already be bound, which is why this is a separate
# resource rather than an argument on the binding.
resource "azurerm_app_service_managed_certificate" "apex" {
  count                      = local.enabled
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.apex[0].id
}

resource "azurerm_app_service_managed_certificate" "www" {
  count                      = local.enabled
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.www[0].id
}

# SNI SSL: many certificates share one front-end IP, and the client names the
# host it wants during the TLS handshake. The alternative, IP-based SSL,
# dedicates an IP per certificate and costs extra.
resource "azurerm_app_service_certificate_binding" "apex" {
  count               = local.enabled
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.apex[0].id
  certificate_id      = azurerm_app_service_managed_certificate.apex[0].id
  ssl_state           = "SniEnabled"
}

resource "azurerm_app_service_certificate_binding" "www" {
  count               = local.enabled
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.www[0].id
  certificate_id      = azurerm_app_service_managed_certificate.www[0].id
  ssl_state           = "SniEnabled"
}
