module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags = {
    project = "az-104-portfolio"
    domain  = "containers"
  }
}

module "registry" {
  source = "../../modules/container-registry"

  name                = var.acr_name
  resource_group_name = module.resource_group.name
  location            = var.location
  sku                 = "Basic"

  tags = {
    project = "az-104-portfolio"
    domain  = "containers"
  }
}

# One identity shared by both container hosts. User-assigned rather than
# system-assigned so the AcrPull role can be granted before either container
# exists - a system-assigned identity only exists once its resource does,
# which would mean the first pull happens before the role is in place.
resource "azurerm_user_assigned_identity" "pull" {
  name                = "id-containers-pull"
  resource_group_name = module.resource_group.name
  location            = var.location

  tags = {
    project = "az-104-portfolio"
    domain  = "containers"
  }
}

module "acr_pull" {
  source = "../../modules/rbac-assignment"

  scope                = module.registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.pull.principal_id
}

# Azure Container Instance: a single container, billed per second, no
# orchestration, no scaling. Suited to short jobs and simple always-on
# containers.
resource "azurerm_container_group" "aci" {
  name                = "aci-az104-web"
  resource_group_name = module.resource_group.name
  location            = var.location
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = var.aci_dns_label

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.pull.id]
  }

  image_registry_credential {
    server                    = module.registry.login_server
    user_assigned_identity_id = azurerm_user_assigned_identity.pull.id
  }

  container {
    name   = "web"
    image  = "${module.registry.login_server}/${var.image_name}:${var.image_tag}"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  # The role assignment must exist before the first image pull is attempted.
  depends_on = [module.acr_pull]

  tags = {
    project = "az-104-portfolio"
    domain  = "containers"
  }
}

# A Container Apps environment needs a Log Analytics workspace for its logs.
# PerGB2018 is the standard pricing tier; the first 5 GB/month is free.
resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-az104-containers"
  resource_group_name = module.resource_group.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    project = "az-104-portfolio"
    domain  = "containers"
  }
}

resource "azurerm_container_app_environment" "this" {
  name                       = "cae-az104-containers"
  resource_group_name        = module.resource_group.name
  location                   = var.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  tags = {
    project = "az-104-portfolio"
    domain  = "containers"
  }
}

# Azure Container App: the managed option, with revisions, built-in ingress
# and scale to zero. Same image as the container instance above, so the only
# thing being compared is the hosting model.
resource "azurerm_container_app" "app" {
  name                         = "ca-az104-web"
  resource_group_name          = module.resource_group.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.pull.id]
  }

  registry {
    server   = module.registry.login_server
    identity = azurerm_user_assigned_identity.pull.id
  }

  template {
    # Scale to zero when idle: no replicas running means nothing to pay for,
    # at the cost of a cold start on the next request.
    min_replicas = 0
    max_replicas = 2

    container {
      name   = "web"
      image  = "${module.registry.login_server}/${var.image_name}:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  depends_on = [module.acr_pull]

  tags = {
    project = "az-104-portfolio"
    domain  = "containers"
  }
}
