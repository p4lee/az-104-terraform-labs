# AZ-104 Terraform portfolio

Infrastructure-as-Code implementation of hands-on labs for the Microsoft
AZ-104 (Azure Administrator) exam, organized by exam domain.

## Layout

    terraform/
      modules/            reusable building blocks (resource group, RBAC assignment, policy assignment, ...)
      bootstrap/          one-time setup: creates the remote state storage account
      exercises/
        01-governance-rbac-policy/   RBAC, Azure Policy, locks, tags
        02-storage/                   planned
        03-compute/                   VMs, disks, zones, encryption at host, scale sets
        04-networking/                planned
        05-monitoring-backup/         planned

Each exercise is its own root Terraform config with its own state file,
composed from the shared modules. This mirrors a common real-world pattern
(shared modules + separate environment/root configs) rather than one
monolithic config for everything.

## Prerequisites

- Terraform >= 1.7 and Azure CLI installed on your machine
  (see: https://developer.hashicorp.com/terraform/install and
  https://learn.microsoft.com/cli/azure/install-azure-cli)
- `az login`, then `az account set --subscription "<name-or-id>"` pointed at
  the free-trial subscription
- The bootstrap config applied once (see `bootstrap/README.md`)

## Order of operations

1. `bootstrap/` - once, creates the remote state storage account
2. `exercises/01-governance-rbac-policy/` - identities and governance
3. `exercises/03-compute/` - virtual machines
4. Remaining exercises, added as each exam domain is covered

## Cost and safety notes

- Everything here is sized to stay within the free-trial credit and the
  always-free tiers where possible, but nothing stops you from
  accidentally provisioning something bigger - check `terraform plan`
  before every `apply`.
- Resource locks (`CanNotDelete`) are used deliberately on some resources;
  each exercise's README says how to remove them before `terraform destroy`.
- Run `terraform destroy` on an exercise once you're done studying that
  topic, to avoid burning through the $200 credit on idle resources.
