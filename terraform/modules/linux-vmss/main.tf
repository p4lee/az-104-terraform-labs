# Flexible orchestration: the current recommended scale set mode. Instances
# are regular VMs you can see and manage individually, spread across zones.
resource "azurerm_orchestrated_virtual_machine_scale_set" "this" {
  name                        = var.name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  sku_name                    = var.size
  instances                   = var.instance_count
  zones                       = var.zones
  platform_fault_domain_count = 1 # with zones, the zone itself is the fault boundary
  encryption_at_host_enabled  = var.encryption_at_host_enabled

  os_profile {
    linux_configuration {
      admin_username                  = var.admin_username
      disable_password_authentication = true

      admin_ssh_key {
        username   = var.admin_username
        public_key = var.admin_ssh_public_key
      }
    }
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Standard SSD rather than the 64 GiB Premium SSD used on the single VM:
  # the free account only covers a limited number of Premium disks, and the
  # single VM already uses one. Standard SSD costs cents per instance.
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  network_interface {
    name    = "${var.name}-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_id
    }
  }

  tags = var.tags

  # Autoscale changes the instance count at runtime. Without this, every
  # `terraform apply` would reset it back to var.instance_count and fight
  # the autoscaler.
  lifecycle {
    ignore_changes = [instances]
  }
}

resource "azurerm_monitor_autoscale_setting" "this" {
  count               = var.autoscale_enabled ? 1 : 0
  name                = "${var.name}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_orchestrated_virtual_machine_scale_set.this.id

  profile {
    name = "cpu-based"

    capacity {
      default = var.instance_count
      minimum = var.autoscale_min
      maximum = var.autoscale_max
    }

    # Scale out: average CPU above 75% over 5 minutes -> add 1 instance
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_orchestrated_virtual_machine_scale_set.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # Scale in: average CPU below 25% over 5 minutes -> remove 1 instance
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_orchestrated_virtual_machine_scale_set.this.id
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
