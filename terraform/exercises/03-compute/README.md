# Exercise 03 - Compute (Virtual Machines and Scale Sets)

Terraform source: `terraform/exercises/03-compute/`
Exam domain: Deploy and manage Azure compute resources (20-25% of AZ-104)

## Depends on exercise 04 (networking)

This exercise creates **compute only**. The virtual network, subnets, NSGs
and NAT gateway live in `exercises/04-networking/`, in their own resource
group (`rg-az104-networking`). This exercise reads 04's `subnet_ids` output
from 04's state file with `terraform_remote_state`.

- Apply order: **04 first, then 03**.
- Destroy order: **03 first, then 04** (04's subnets can't be deleted while
  VMs are still attached to them).

This mirrors a common real-world split: a shared network layer owned by
one team, with workload layers plugging into it.

## What is built

- A resource group (`rg-az104-compute`)
- A Linux VM (`modules/linux-vm`) in `snet-vms` - optional, see
  `deploy_single_vm` below:
  - `Standard_B2ats_v2` size, deployed into availability zone 1
  - SSH-key authentication only (no password auth)
  - 64 GiB Premium SSD OS disk - the specific size/tier that qualifies this
    VM size for the Azure free account's 750 free hours/month
  - Encryption at host enabled
  - A small (4 GiB) Standard HDD data disk, attached separately from the OS
    disk, to demonstrate disk management as its own concept
- A Linux VM scale set `vmss-az104-compute` (`modules/linux-vmss`) in `snet-vmss`:
  - **Flexible orchestration** - Microsoft's current recommendation and the
    portal default. Instances are ordinary VMs you can manage one by one.
    Uniform orchestration (identical instances, with an explicit Manual /
    Automatic / Rolling upgrade policy) is the older mode and still shows up
    on the exam.
  - Instances may be placed in zones 1, 2 and 3 (`vmss_zones`), fault
    domain count 1 (the zone is the fault boundary)
  - `Standard_B2ats_v2`, SSH keys only, encryption at host, Standard SSD OS disk
  - Starts with 1 instance
  - CPU-based autoscale: min 1, max 2. Scale out +1 when average CPU > 75%
    for 5 minutes, scale in -1 when < 25%, 5-minute cooldown
  - `lifecycle { ignore_changes = [instances] }` so `terraform apply`
    doesn't reset the instance count that autoscale has changed

No resource lock, unlike exercise 01 - VMs are something you want to tear
down quickly to stop the clock on free-tier hours, not protect from deletion.

## Prerequisites

1. `terraform/bootstrap` already applied (same as every exercise).
2. `exercises/04-networking` applied.
3. The `EncryptionAtHost` feature registered on your subscription:
   ```
   az feature register --namespace Microsoft.Compute --name EncryptionAtHost
   az feature show --namespace Microsoft.Compute --name EncryptionAtHost --query properties.state
   ```
   Wait until this shows `"Registered"` (can take several minutes), then:
   ```
   az provider register --namespace Microsoft.Compute
   ```
4. An SSH key pair - **RSA, not ed25519**. Azure's `admin_ssh_key` field on
   virtual machines only accepts RSA keys, even though ed25519 works fine
   for SSH in general:
   ```
   ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\az104-vm" -C "az104-lab"
   ```

## Run it

    cd terraform/exercises/03-compute
    cp terraform.tfvars.example terraform.tfvars
    # edit terraform.tfvars: SSH public key + the two state_* values
    terraform init `
      -backend-config="resource_group_name=<from bootstrap output>" `
      -backend-config="storage_account_name=<from bootstrap output>"
    terraform plan
    terraform apply

The `state_resource_group_name` / `state_storage_account_name` variables
repeat the `-backend-config` values. Terraform doesn't let a configuration
read its own backend settings, so reading another exercise's state needs
them passed in again.

## vCPU quota and `deploy_single_vm`

The free trial allows **4 vCPUs per region**. The VM and each scale set
instance use 2 each, so VM + 2 scale set instances (6 vCPUs) doesn't fit.

**Deallocating a VM does not free quota** - quota counts cores of all VMs
that exist, allocated or deallocated
([Check vCPU quotas](https://learn.microsoft.com/azure/virtual-machines/quotas)).
This was learned the hard way: with the VM deallocated, autoscale still
failed to add a second instance with `OperationNotAllowed ... exceeding
approved Total Regional Cores quota`.

To free the quota, remove the VM instead:

    # terraform.tfvars
    deploy_single_vm = false

`terraform apply` then deletes the VM, its NIC and disks. Set it back to
`true` (or remove the line) to recreate it.

`Standard_B1s` (1 vCPU) would fit more instances, but it isn't offered in
swedencentral.

## Capacity is not the same as quota

Quota is what your subscription is *allowed* to use. Capacity is whether
Azure *physically has* free hardware of that size in that zone right now.
Both failed during this exercise:

- `ZonalAllocationFailed` when starting the VM in zone 1 - fixed by moving
  the VM to zone 3 (`vm_zone = "3"` in terraform.tfvars)
- `OverconstrainedZonalAllocationRequest` when creating the scale set in
  zones 1 and 2 - fixed by allowing all three zones (`vmss_zones`, default
  `["1","2","3"]`), which is also Microsoft's high-availability
  recommendation

Fixes for capacity errors: allow more zones, try another VM size, or
another region. A quota increase does not help.

## Troubleshooting: Terraform can't destroy a deallocated VM

Before deleting a VM, the azurerm provider powers it off. If the VM is
already **deallocated**, Azure rejects that with `409 Conflict ...
Operation 'powerOff' is not allowed ... since the VM is either deallocated`
and the destroy stops. Fix: start the VM first, then destroy. If it can't
start (e.g. no capacity), delete it with `az vm delete` - and delete its OS
disk too, which the CLI leaves behind - then run `terraform destroy` again.

## Outbound connectivity

Both subnets are **private** (no default outbound access) and use the NAT
gateway from exercise 04 as their explicit outbound method. This matters
more for the scale set than for the VM: **Flexible scale sets never get
default outbound access**, and instances created by autoscale need an
explicit outbound method. Before the NAT gateway existed, instances
couldn't reach Ubuntu's package mirrors at all (`apt-get update` timed out).

## Cost notes

- The VM's compute hours are free up to 750 hours/month on `Standard_B2ats_v2`
  with the 64 GiB Premium SSD OS disk - staying under that limit means no
  charge for the VM itself. Scale set instances draw from the same 750 hours.
- The data disk and the scale set's Standard SSD OS disks cost a few cents
  a month each.
- The NAT gateway (exercise 04) costs roughly EUR 1/day while it exists.
- Run `terraform destroy` (here, then in 04) when you're done studying, to
  stay within the free hours and avoid the NAT gateway's running cost.

## What this demonstrates for AZ-104

- Creating and sizing a virtual machine; deploying to an availability zone
- Managing VM disks: OS disk configuration and an attached data disk
- Configuring encryption at host
- SSH-key-based authentication instead of passwords (RSA only, on Azure)
- VM scale sets: Flexible vs Uniform orchestration, zone spreading,
  CPU-based autoscale rules and cooldowns
- Troubleshooting a failed scale-out (vCPU quota, via the activity log)
- Flexible scale sets and explicit outbound connectivity

Not covered here: moving a VM to another resource group/subscription/region
(an operational action better demonstrated live than as a persistent
Terraform resource).
