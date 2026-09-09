module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags = {
    project = "az-104-portfolio"
    domain  = "identities-and-governance"
  }
}

# Resource lock: protects this exercise's resource group from accidental deletion
# while other exercises are still being built out.
resource "azurerm_management_lock" "no_delete" {
  name       = "no-delete"
  scope      = module.resource_group.id
  lock_level = "CanNotDelete"
  notes      = "Prevents accidental deletion while learning AZ-104 governance concepts."
}

# Azure RBAC: assign the built-in Reader role to the signed-in account at
# resource group scope. This is a different system from Entra directory
# roles - it's scope-based (management group / subscription / resource
# group / resource), not directory-wide.
module "reader_assignment" {
  source = "../../modules/rbac-assignment"

  scope                 = module.resource_group.id
  role_definition_name  = "Reader"
  principal_id          = data.azurerm_client_config.current.object_id
}

# Azure Policy: require a "project" tag on every resource created in this
# resource group, using a built-in policy definition.
data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag on resources"
}

module "require_tag_policy" {
  source = "../../modules/policy-assignment"

  name                 = "require-project-tag"
  resource_group_id    = module.resource_group.id
  policy_definition_id = data.azurerm_policy_definition.require_tag.id
  display_name         = "Require 'project' tag in this resource group"
  description          = "AZ-104 governance exercise: enforce a required tag via Azure Policy."
  parameters = jsonencode({
    tagName = {
      value = "project"
    }
  })
}
