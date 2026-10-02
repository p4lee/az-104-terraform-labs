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
