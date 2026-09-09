# Exercise 01 - Identities and governance

Maps to AZ-104 study-plan.md days 1-3 and the "Manage Azure identities and
governance" exam domain (20-25% of the exam).

## What this builds

- A resource group (`modules/resource-group`)
- A `CanNotDelete` resource lock on it
- An Azure RBAC role assignment (built-in `Reader` role, scoped to the
  resource group) - deliberately using `modules/rbac-assignment`, which is
  generic enough to reuse for any scope later
- An Azure Policy assignment (built-in "Require a tag on resources"
  definition) that enforces a `project` tag on anything created in this
  resource group

## Why these specific resources

RBAC and Policy are the two parts of the governance domain that are
genuinely new territory coming from an Entra-focused background - they're
scoped to management groups/subscriptions/resource groups/resources, not
the Entra directory. The resource lock and tags are quick, cheap ways to
show the same concepts (protection and organization) that show up
throughout the rest of the exam.

## Prerequisites

1. `terraform/bootstrap` has been applied (see its README) - you need its
   `resource_group_name` and `storage_account_name` outputs.
2. Terraform and Azure CLI installed locally.
3. `az login` completed, subscription selected with `az account set --subscription "<name-or-id>"`.

## Run it

    cd terraform/exercises/01-governance-rbac-policy
    terraform init \
      -backend-config="resource_group_name=<from bootstrap output>" \
      -backend-config="storage_account_name=<from bootstrap output>"
    terraform plan
    terraform apply

## Clean up

Resource locks block deletion on purpose - remove the lock before
destroying:

    terraform apply -destroy -target azurerm_management_lock.no_delete
    terraform destroy
