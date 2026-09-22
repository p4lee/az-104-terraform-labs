# Exercise 04 - Networking

Maps to the AZ-104 "Implement and manage virtual networking" exam domain
(15-20% of the exam).

## Status

**Step 1 - network foundation: built.** The rest of the networking topics
(peering, user-defined routes, application security groups, Azure Bastion,
service/private endpoints, Azure DNS, load balancers, and an `import`
exercise) will be added to this exercise later.

## What is built (step 1)

- A resource group `rg-az104-networking` - networking has its own resource
  group, separate from the workloads that use it
- A virtual network `vnet-az104-workload` (`10.10.0.0/16`) with two subnets:
  - `snet-vms` (`10.10.1.0/24`) - for the single VM in exercise 03
  - `snet-vmss` (`10.10.2.0/24`) - for the scale set in exercise 03
- Both subnets are **private** (`default_outbound_access_enabled = false`):
  no implicit "default outbound" public IP. This is Azure's default for new
  VNets since March 2026.
- One NSG per subnet (`nsg-vms`, `nsg-vmss`), no custom rules yet. Azure's
  default rules allow VNet-internal traffic and deny inbound internet traffic.
- A NAT gateway `nat-az104-workload` (Standard SKU, no zone) with a static,
  zone-redundant Standard public IP, attached to both subnets as their
  explicit outbound method

## Outputs used by other exercises

Exercise 03 reads these through `terraform_remote_state`:

| Output | Used for |
|---|---|
| `subnet_ids` | Map of subnet name to ID - 03 places the VM and scale set with it |
| `nat_public_ip` | The IP outbound traffic from both subnets appears to come from |

Renaming or removing an output breaks exercise 03 at plan time - treat
outputs as an interface.

## Run it

    cd terraform/exercises/04-networking
    terraform init `
      -backend-config="resource_group_name=<from bootstrap output>" `
      -backend-config="storage_account_name=<from bootstrap output>"
    terraform plan
    terraform apply

Apply this **before** exercise 03, and destroy it **after** exercise 03.

## Cost notes

- VNets, subnets and NSGs are free.
- The NAT gateway is roughly EUR 1/day plus a small per-GB data charge, and
  its public IP a few euros a month. Destroy this exercise when you're not
  using it (after destroying exercise 03).

## Design notes

- **Standard NAT gateway, "no zone":** Azure picks the zone. If that zone
  fails, outbound stops for both subnets. The newer **StandardV2** SKU is
  zone-redundant and is the production choice; Standard keeps this lab
  simple.
- **Public IP zones set to `["1","2","3"]`:** Standard public IPs are
  zone-redundant by default now, so declaring it explicitly keeps
  Terraform's state in line with what Azure creates.
- **Subnet map instead of fixed subnets:** `modules/virtual-network` takes a
  map of subnets, so later steps (e.g. a Bastion subnet) are one line each.
