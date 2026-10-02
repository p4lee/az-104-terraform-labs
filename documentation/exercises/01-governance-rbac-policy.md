# Exercise 01 - Identities and governance

Terraform source: `terraform/exercises/01-governance-rbac-policy/`
Exam domain: Manage Azure identities and governance (20-25% of AZ-104)

## What was built

- A resource group (`rg-az104-governance`)
- A `CanNotDelete` resource lock on it
- An Azure RBAC role assignment: built-in `Reader` role, scoped to the resource group
- An Azure Policy assignment: built-in "Require a tag on resources" definition,
  enforcing a `project` tag on anything created inside the resource group
- A monthly cost budget (`budget-governance`, €20) with alerts at 50% and 90% of spend

## Region note

Originally applied in West Europe, then destroyed and recreated in Sweden Central
once swedencentral was picked as the project's standard region (see claude.md).

## Terraform outputs

```
resource_group_name  = "rg-az104-governance"
resource_group_id    = "/subscriptions/<subscription-id>/resourceGroups/rg-az104-governance"
policy_assignment_id = "/subscriptions/<subscription-id>/resourceGroups/rg-az104-governance/providers/Microsoft.Authorization/policyAssignments/require-project-tag"
budget_id             = "/subscriptions/<subscription-id>/resourceGroups/rg-az104-governance/providers/Microsoft.Consumption/budgets/budget-governance"
```

(subscription ID redacted before committing - it's not a secret, but no reason to publish it on a public repo)

## Verification in the Azure portal

| # | Screenshot | What it shows |
|---|---|---|
| 1 | `screenshots/01-resource-group-overview.png` | Resource group exists, region = Sweden Central |
| 2 | `screenshots/02-resource-lock.png` | `no-delete` lock, level `CanNotDelete` |
| 3 | `screenshots/03-iam-role-assignment.png` | Signed-in account has `Reader` at resource group scope |
| 4 | `screenshots/04-policy-compliance.png` | Tag-enforcement policy assignment, with its compliance state |
| 5 | `screenshots/05-budget.png` | Budget `budget-governance`, amount and both alert thresholds |

## What this demonstrates for AZ-104

- Azure RBAC: assigning a built-in role at a specific scope (resource group),
  and how that's a separate system from Entra directory roles
- Azure Policy: assigning a built-in policy definition with parameters, at
  resource group scope
- Resource locks: protecting a resource group from accidental deletion
- Resource groups and tagging as an organizing/governance mechanism
- Cost management: a subscription/resource-group budget with threshold-based alerts
- Azure Advisor cost recommendations weren't built here - Advisor has no Terraform
  resource, it's a read-only recommendation engine reviewed directly in the portal
