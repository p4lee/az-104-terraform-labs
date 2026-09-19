# Exercise 03 - Compute (Virtual Machines)

Terraform source: `terraform/exercises/03-compute/`
Exam domain: Deploy and manage Azure compute resources (20-25% of AZ-104)

## What was built

- A resource group (`rg-az104-compute`)
- A minimal virtual network and subnet (`vnet-compute` / `snet-vms`,
  `10.10.0.0/16` / `10.10.1.0/24`) - just enough for the VM to attach to;
  peering, endpoints, and deeper NSG rules are exercise 04's job
- A network security group with no custom rules - Azure's built-in defaults
  already deny inbound internet traffic and allow VNet-internal traffic,
  which is correct for a VM with no public IP
- A Linux VM (`vm-az104-compute`):
  - `Standard_B2ats_v2` size, deployed into availability zone 1
  - SSH-key authentication only (no password auth)
  - 64 GiB Premium SSD OS disk - the specific size/tier that qualifies this
    VM size for the Azure free account's 750 free hours/month
  - Encryption at host enabled
  - A small (4 GiB) Standard HDD data disk, attached separately from the
    OS disk, to demonstrate disk management as its own concept
- No public IP - intentional. Adding one (or Azure Bastion) is a deliberate
  cost/access tradeoff left for the networking exercise rather than added
  here by default.

No resource lock this time, unlike exercise 01 - a VM is something you want
to tear down quickly to stop the clock on free-tier hours or avoid cost,
not something to protect from deletion.

## Note: exercise 02 is still pending

Numbering jumps from 01 (governance) straight to 03 (compute) because
exercise 02 - storage, AZ-104's "Implement and manage storage" domain -
hasn't been built yet. Flagging this here so the gap is visible rather than
silently skipped; it'll be filled in and this note removed once it exists.

## About the "default outbound access" portal alert

After deploying, the VM's Overview blade shows an alert: *"Your VM has a
default outbound IP, which is insecure and will no longer be assigned by
default for new subnets after March 2026."* This is expected here, not a
misconfiguration:

- The subnet has no explicit outbound method attached - no NAT gateway, no
  public IP on the NIC, no standard load balancer with outbound rules, no
  UDR to a firewall/NVA. Without one of those, Azure transparently assigns
  a Microsoft-owned "default outbound" public IP so the VM can still reach
  the internet/Azure endpoints. That implicit fallback is what triggers
  the alert.
- This behavior is being retired for *new* deployments only: virtual
  networks created via API versions released after March 31, 2026 default
  new subnets to `defaultOutboundAccess = false` ("private"), requiring an
  explicit outbound method. Existing VNets/subnets aren't retroactively
  changed.
- The fix - a NAT gateway as the explicit outbound method - is deliberately
  deferred to exercise 04 (networking) to keep this exercise's resource set
  focused on compute concepts. The alert is left in place here and
  destroyed with everything else when the exercise is torn down.

## Terraform outputs

```
resource_group_name = "rg-az104-compute"
vm_id                = "/subscriptions/<subscription-id>/resourceGroups/rg-az104-compute/providers/Microsoft.Compute/virtualMachines/vm-az104-compute"
vm_private_ip        = "10.10.1.4"
data_disk_id         = "/subscriptions/<subscription-id>/resourceGroups/rg-az104-compute/providers/Microsoft.Compute/disks/vm-az104-compute-data"
```

(subscription ID redacted before committing - it's not a secret, but no reason to publish it on a public repo)

## Verification in the Azure portal

| # | Screenshot | What it shows |
|---|---|---|
| 1 | `screenshots/01-vm-overview.png` | VM size (`Standard_B2ats_v2`), zone 1, region Sweden Central |
| 2 | `screenshots/02-disks-and-encryption.png` | OS disk (64 GiB Premium SSD), attached data disk, encryption-at-host status |
| 3 | `screenshots/03-networking.png` | Private IP `10.10.1.4`, confirming no public IP is attached |
| 4 | `screenshots/04-default-outbound-alert.png` | The portal's default-outbound-IP alert - evidence of relying on implicit outbound access (explained above) |

## What this demonstrates for AZ-104

- Creating and sizing a virtual machine
- Deploying to an availability zone
- Managing VM disks: OS disk configuration and an attached data disk
- Configuring encryption at host
- SSH-key-based authentication instead of passwords (RSA only, on Azure)
- Basic virtual network/subnet/NSG as compute prerequisites (deeper
  networking topics are exercise 04)
- Default outbound access vs. explicit outbound methods (NAT gateway,
  public IP, load balancer, UDR) - exam-relevant given the March 2026
  behavior change for new subnets

Not covered here: moving a VM to another resource group/subscription/region
(an operational action better demonstrated live than as a persistent
Terraform resource), and VM Scale Sets (planned as a follow-up addition).
