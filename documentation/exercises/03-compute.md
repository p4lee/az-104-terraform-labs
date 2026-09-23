# Exercise 03 - Compute (Virtual Machines and Scale Sets)

Terraform source: `terraform/exercises/03-compute/`
Exam domain: Deploy and manage Azure compute resources (20-25% of AZ-104)

## What was built

- Resource group `rg-az104-compute`
- A Linux VM `vm-az104-compute` (optional, see `deploy_single_vm`):
  `Standard_B2ats_v2`, availability zone 3, SSH keys only, 64 GiB Premium SSD
  OS disk, encryption at host, plus a separate 4 GiB Standard HDD data disk
- A Linux VM scale set `vmss-az104-compute` in **Flexible orchestration**:
  same size, zones 1-3, Standard SSD OS disks, starts at 1 instance
- A CPU-based autoscale setting: min 1, max 2, scale out above 75% average
  CPU over 5 minutes, scale in below 25%, 5-minute cooldown

Networking (VNet, subnets, NSGs, NAT gateway) is **not** part of this
exercise - it lives in exercise 04 and its own resource group. This
exercise reads 04's `subnet_ids` output via `terraform_remote_state`, so
04 is applied first and destroyed last.

## Notable decisions

- **Flexible over Uniform orchestration.** Flexible is Microsoft's current
  recommendation and the portal default; instances are ordinary VMs you can
  manage individually. Uniform's explicit upgrade policy (Manual /
  Automatic / Rolling) still appears on the exam.
- **`lifecycle { ignore_changes = [instances] }`** on the scale set, so
  autoscale owns the instance count and `terraform apply` doesn't reset it.
- **`deploy_single_vm` toggle** to remove the VM and free its 2 vCPUs
  when the scale set needs the room.
- **`ignore_changes = [vm_agent_platform_updates_enabled]`** on the VM
  module. Azure turns that setting on by itself after deployment, which
  otherwise shows as drift on every plan.

## Terraform outputs

Final apply, with the single VM switched off:

```
resource_group_name = "rg-az104-compute"
vmss_id             = "/subscriptions/<subscription-id>/resourceGroups/rg-az104-compute/providers/Microsoft.Compute/virtualMachineScaleSets/vmss-az104-compute"
vmss_name           = "vmss-az104-compute"
vm_id               = null
vm_private_ip       = null
data_disk_id        = null
```

The VM outputs use `one(module.vm[*]...)`, so they return `null` instead of
failing when `deploy_single_vm = false`.

## Verification in the Azure portal

| # | Screenshot | What it shows |
|---|---|---|
| 1 | `screenshots/01-vm-overview.png` | VM size, zone 3, Sweden Central, no default-outbound alert |
| 2 | `screenshots/02-disks-and-encryption.png` | 64 GiB Premium SSD OS disk, attached data disk, encryption at host |
| 3 | `screenshots/03-networking.png` | Private IP in `vnet-az104-workload/snet-vms`, no public IP |
| 4 | `screenshots/04-outbound-via-nat.png` | `curl api.ipify.org` from the VM returning the NAT gateway's public IP |
| 5 | `screenshots/05-vmss-overview.png` | Flexible orchestration, `Standard_B2ats_v2`, zones 1-3 |
| 6 | `screenshots/06-vmss-autoscale-rules.png` | Autoscale rules: >75% out, <25% in, min 1 / max 2 / default 1 |
| 7 | `screenshots/07-vmss-cpu-metric.png` | CPU at 100% during the stress test |
| 8 | `screenshots/08-vmss-autoscale-scale-out.png` | "Autoscale scale up completed", observed capacity 2 |
| 9 | `screenshots/09-vmss-instances-zones.png` | Two instances: one Running, one Creating (allocation later failed - see below) |
| 10 | `screenshots/10-vmss-autoscale-scale-in.png` | Scale-in back to 1 after CPU dropped |

CPU load was generated with `az vm run-command invoke` and
`systemd-run --unit=cpu-stress timeout 900 sh -c 'yes > /dev/null & yes > /dev/null & wait'` -
no package install needed, which matters because the instances only reach
the internet through the NAT gateway.

## Troubleshooting log

Everything below actually happened while building this exercise. All of it
is exam-relevant.

**1. vCPU quota, and deallocated VMs still count.**
The free trial allows 4 Total Regional vCPUs. With the VM (2 vCPUs) plus one
scale set instance (2), autoscale's second instance failed with
`OperationNotAllowed ... exceeding approved Total Regional Cores quota`.
Deallocating the VM did not help: quota counts the cores of every VM that
exists, allocated or deallocated
([Check vCPU quotas](https://learn.microsoft.com/azure/virtual-machines/quotas)).
Removing the VM (`deploy_single_vm = false`) is what frees quota.

**2. Quota is released with a delay, and the usage view lags.**
Creating something straight after deleting a VM repeatedly failed on quota
even though `az vm list-usage` already showed the lower number. Azure's
allocator and the usage API catch up at different speeds. Fix: wait a few
minutes between a delete and a create that needs those cores.

**3. Quota is not capacity.**
`ZonalAllocationFailed` (starting the VM in zone 1) and
`OverconstrainedZonalAllocationRequest` (creating the scale set in zones 1
and 2) are capacity errors: Azure simply had no free hardware of that size
in those zones. A quota increase doesn't help. Fixes: allow more zones
(`vmss_zones = ["1","2","3"]`), choose another size, or another region.

**4. "Scale up completed" does not mean the instance exists.**
The autoscale run history can show *scale up completed* while the new VM
never allocates. The autoscale engine only reports that it set the new
target capacity. The activity log is where the VM-level failure shows up.

**5. A failed apply can leave resources behind that aren't in state.**
Twice, a failed scale set creation left a scale set in Azure that Terraform
didn't know about, so the next apply failed with "already exists". After a
failed apply, check with `az resource list -g <rg>` before retrying.

**6. Terraform can't destroy a deallocated VM.**
The provider powers a VM off before deleting it, and Azure rejects
`powerOff` on an already-deallocated VM with `409 Conflict`. The destroy
stops there, leaving the NIC, subnet, VNet and resource group behind. Fix:
start the VM first, then destroy. If it can't start (no capacity), use
`az vm delete`, then delete the OS disk the CLI leaves behind, then destroy.

## What this demonstrates for AZ-104

- Creating and sizing VMs, availability zones, disks and encryption at host
- SSH-key authentication instead of passwords (Azure requires RSA here)
- VM scale sets: Flexible vs Uniform, zone spreading, autoscale rules,
  cooldowns, and manual scaling with `az vmss scale`
- Reading failures out of the Azure activity log
- vCPU quota vs regional capacity, and how each one is fixed
- Layering Terraform configurations with `terraform_remote_state`
