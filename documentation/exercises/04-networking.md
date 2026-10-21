# Exercise 04 - Networking (step 1: network foundation)

Terraform source: `terraform/exercises/04-networking/`
Exam domain: Implement and manage virtual networking (15-20% of AZ-104)

## What was built

- Resource group `rg-az104-networking` - networking gets its own resource
  group, separate from the workloads that use it
- Virtual network `vnet-az104-workload` (`10.10.0.0/16`) with two subnets:
  - `snet-vms` (`10.10.1.0/24`) for the single VM in exercise 03
  - `snet-vmss` (`10.10.2.0/24`) for the scale set in exercise 03
- One NSG per subnet: `nsg-vms` and `nsg-vmss`, with no custom rules yet.
  Azure's default rules already allow VNet-internal traffic and deny
  inbound internet traffic.
- NAT gateway `nat-az104-workload` (Standard SKU, no zone) with a static,
  zone-redundant Standard public IP, attached to both subnets

## Notable decisions

- **Private subnets (`default_outbound_access_enabled = false`).** No
  implicit "default outbound" public IP. This is Azure's default for new
  VNets since March 2026, and it removes the portal's default-outbound
  warning that exercise 03 showed before this exercise existed.
- **NAT gateway as the explicit outbound method.** Needed by more than just
  the VM: **Flexible scale sets never get default outbound access**, and
  instances created by autoscale need an explicit outbound method
  ([scale set networking](https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-networking#explicit-network-outbound-connectivity-for-flexible-scale-sets)).
  Before the NAT gateway existed, `apt-get update` on a scale set instance
  timed out against Ubuntu's mirrors.
- **Standard SKU, "no zone".** Azure picks the zone; if it fails, outbound
  stops for both subnets. The newer StandardV2 SKU is zone-redundant and
  would be the production choice.
- **Public IP zones declared as `["1","2","3"]`.** Standard public IPs are
  zone-redundant by default now, so saying so explicitly keeps Terraform's
  state in line with what Azure creates and avoids drift.
- **Networking as its own layer.** Exercise 03 reads this exercise's
  outputs with `terraform_remote_state`, which mirrors the common split of
  a shared network layer and separate workload layers. Apply order is 04
  then 03; destroy order is the reverse.

## Terraform outputs

```
resource_group_name = "rg-az104-networking"
vnet_name           = "vnet-az104-workload"
vnet_id             = "/subscriptions/<subscription-id>/resourceGroups/rg-az104-networking/providers/Microsoft.Network/virtualNetworks/vnet-az104-workload"
subnet_ids          = {
  "snet-vms"  = ".../subnets/snet-vms"
  "snet-vmss" = ".../subnets/snet-vmss"
}
nat_public_ip       = "57.174.18.90"
```

`subnet_ids` and `nat_public_ip` are the interface other exercises depend
on. Renaming an output breaks exercise 03 at plan time.

## Verification in the Azure portal

| # | Screenshot | What it shows |
|---|---|---|
| 1 | `screenshots/01-vnet-subnets.png` | Both subnets with their NSGs (`nsg-vms`, `nsg-vmss`) and address ranges |
| 2 | `screenshots/02-nat-gateway-subnets.png` | NAT gateway attached to both subnets of `vnet-az104-workload` |
| 3 | `screenshots/03-dns-zone-overview.png` | The DNS zone and the four Azure nameservers it publishes |
| 4 | `screenshots/04-dns-delegation-nslookup.png` | `nslookup -type=NS` against Google's resolver returning those nameservers - proof the registrar delegation took effect |
| 5 | `screenshots/05-dns-zone-records.png` | Record sets after exercise 03c bound its hostnames: NS, SOA, the apex A record, the `www` CNAME and both `asuid` TXT records |

Outbound was verified from the VM in exercise 03: `curl api.ipify.org`
returned the NAT gateway's public IP (screenshot 04 of exercise 03).

## Delegation, and what the zone is used for

Creating the zone does nothing by itself. The domain's registrar had to be
pointed at the four nameservers the zone publishes (`dns_zone_name_servers`
output); until then the zone is authoritative for nobody. Delegation took
effect within the hour and was confirmed with:

    nslookup -type=NS cloud-consult-lab.site 8.8.8.8

Exercise 03c then added records to this zone for its App Service custom
domains - an apex A record, a `www` CNAME and two `asuid` TXT records -
reading the zone name and resource group from this exercise's outputs.
Those records were removed again when 03c was destroyed; the zone itself
stays, so the delegation does not have to be redone.

## What this demonstrates for AZ-104

- Creating virtual networks and subnets, and associating NSGs with subnets
- Creating a public DNS zone and delegating a real domain to Azure DNS
- Private subnets and default outbound access, including the March 2026
  change
- NAT gateways as an explicit outbound method, and why Flexible scale sets
  require one
- Standard public IP SKUs and zone redundancy
- Splitting infrastructure into layers with a stable output contract

## Cost note: the NAT gateway is the expensive part

VNets, subnets, NSGs and a DNS zone cost nothing or near nothing (the zone
is about EUR 0.45/month). The NAT gateway and its public IP are roughly
EUR 33/month and are only useful while compute is running in these subnets,
so it is deployed when an exercise needs outbound access and removed again
afterwards.

## Still to come in this exercise

VNet peering, user-defined routes, application security groups, Azure
Bastion, service and private endpoints, load balancers, and an `import`
exercise that brings a hand-created resource under Terraform.
