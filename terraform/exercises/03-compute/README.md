# Exercise 03 - Compute (Virtual Machines)

Terraform source: `terraform/exercises/03-compute/`
Study plan reference: `study-plan.md`, days 4-5
Exam domain: Deploy and manage Azure compute resources (20-25% of AZ-104)

## What was built

- A resource group (`rg-az104-compute`)
- A minimal virtual network and subnet (`modules/virtual-network`) - just enough
  for the VM to attach to; peering, endpoints, and deeper NSG rules are
  exercise 04's job
- A network security group with no custom rules (`modules/network-security-group`) -
  Azure's built-in defaults already deny inbound internet traffic and allow
  VNet-internal traffic, which is correct for a VM with no public IP
- A Linux VM (`modules/linux-vm`):
  - `Standard_B2ats_v2` size, deployed into availability zone 1
  - SSH-key authentication only (no password auth)
  - 64 GiB Premium SSD OS disk - the specific size/tier that qualifies this
    VM size for the Azure free account's 750 free hours/month
  - Encryption at host enabled
  - A small (4 GiB) Standard HDD data disk, attached separately from the OS
    disk, to demonstrate disk management as its own concept

No resource lock this time, unlike exercise 01 - a VM is something you want
to tear down quickly to stop the clock on free-tier hours or avoid cost,
not something to protect from deletion.

## Prerequisites

1. `terraform/bootstrap` already applied (same as every exercise).
2. The `EncryptionAtHost` feature registered on your subscription:
   ```
   az feature register --namespace Microsoft.Compute --name EncryptionAtHost
   az feature show --namespace Microsoft.Compute --name EncryptionAtHost --query properties.state
   ```
   Wait until this shows `"Registered"` (can take several minutes), then:
   ```
   az provider register --namespace Microsoft.Compute
   ```
3. An SSH key pair - **RSA, not ed25519**. Azure's `admin_ssh_key` field on
   virtual machines only accepts RSA keys, even though ed25519 works fine
   for SSH in general:
   ```
   ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\az104-vm" -C "az104-lab"
   ```

## Cost notes

- The VM's compute hours are free up to 750 hours/month on `Standard_B2ats_v2`
  with the 64 GiB Premium SSD OS disk configured here - staying under that
  limit means no charge for the VM itself.
- The data disk (4 GiB Standard HDD) is not part of the free allowance, but
  costs only a few cents a month.
- No public IP is attached, so there's no ~EUR 3.65/month public IP charge -
  intentional. To actually SSH into this VM you'd need to add a public IP
  or Azure Bastion, a deliberate cost/access tradeoff left for the
  networking exercise rather than added here by default.
- Run `terraform destroy` when you're done studying this section, both to
  stay within the free hours and to avoid the data disk's small ongoing cost.

## Run it

    cd terraform/exercises/03-compute
    cp terraform.tfvars.example terraform.tfvars
    # edit terraform.tfvars: paste your RSA SSH public key contents
    terraform init `
      -backend-config="resource_group_name=<from bootstrap output>" `
      -backend-config="storage_account_name=<from bootstrap output>"
    terraform plan
    terraform apply

## What this demonstrates for AZ-104

- Creating and sizing a virtual machine
- Deploying to an availability zone
- Managing VM disks: OS disk configuration and an attached data disk
- Configuring encryption at host
- SSH-key-based authentication instead of passwords (RSA only, on Azure)
- Basic virtual network/subnet/NSG as compute prerequisites (deeper
  networking topics are exercise 04)

Not covered here: moving a VM to another resource group/subscription/region
(an operational action better demonstrated live than as a persistent
Terraform resource), and VM Scale Sets (planned as a follow-up addition).

## About the "default outbound access" portal alert

After deploying, the VM's Overview blade shows an alert: *"Your VM has a
default outbound IP, which is insecure and will no longer be assigned by
default for new subnets after March 2026."* This is expected, not a
misconfiguration, and it's worth understanding for the exam:

- The subnet here has no explicit outbound method attached to it - no NAT
  gateway, no public IP on the NIC, no standard load balancer with
  outbound rules, no UDR to a firewall/NVA. Without one of those, Azure
  transparently assigns the VM a Microsoft-owned "default outbound" public
  IP so it can still reach the internet/Azure endpoints. That implicit
  fallback is what the alert is flagging.
- This behavior is being retired for *new* deployments: virtual networks
  created via API versions released after March 31, 2026 will default new
  subnets to `defaultOutboundAccess = false` ("private"), so VMs in them
  will need one of the explicit methods above. Existing VNets/subnets are
  not retroactively changed.
- The fix - adding a NAT gateway as the explicit outbound method - is
  deliberately deferred to exercise 04 (networking), not added here, to
  keep this exercise's resource set focused on compute concepts. For this
  study VM, the alert is left in place and destroyed along with everything
  else when the exercise is torn down.
