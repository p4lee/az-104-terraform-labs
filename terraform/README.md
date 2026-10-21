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
        03b-containers/               container registry, container instances, container apps
        03c-app-service/              plan, web app, slot swap, autoscale, backup, custom domain + TLS
        04-networking/                shared VNet, subnets, NSGs, NAT gateway, DNS zone (more to come)
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
3. `exercises/04-networking/` - shared network foundation (VNet, subnets, NSGs, NAT gateway)
4. `exercises/03-compute/` - virtual machines and scale sets; reads subnet IDs from 04's state
5. `exercises/03b-containers/` - registry, container instance, container app (independent)
6. `exercises/03c-app-service/` - App Service; reads the DNS zone from 04's state in phase 2
7. Remaining exercises, added as each exam domain is covered

04 is applied before 03 and 03c, because both read its outputs: 03 places
its VMs in 04's subnets, and 03c writes DNS records into 04's zone.
Destroy in the reverse order - workloads first, 04 last.

ARM template and Bicep work lives outside this folder, in `/bicep`,
because those formats are tested directly on the exam.

## Cost and safety notes

- Everything here is sized to stay within the free-trial credit and the
  always-free tiers where possible, but nothing stops you from
  accidentally provisioning something bigger - check `terraform plan`
  before every `apply`.
- Resource locks (`CanNotDelete`) are used deliberately on some resources;
  each exercise's README says how to remove them before `terraform destroy`.
- Run `terraform destroy` on an exercise once you're done studying that
  topic. The subscription started as a free trial and is now
  pay-as-you-go, so idle resources cost real money.
- The expensive items, each destroyed after its exercise is documented:
  App Service plan S1 (~EUR 60/month), NAT gateway and its public IP
  (~EUR 33/month), container registry Basic (~EUR 4.60/month), and any
  running VM or container instance.
- Left running between sessions: the Terraform state storage account,
  the DNS zone and the free networking resources - about EUR 1.50/month.
