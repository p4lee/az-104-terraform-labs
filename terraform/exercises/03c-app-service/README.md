# Exercise 03c - App Service

Terraform source: `terraform/exercises/03c-app-service/`
Exam domain: Deploy and manage Azure compute resources (20-25% of AZ-104)

## Depends on exercise 04 (networking)

Phase 2 writes DNS records into the zone created by
`exercises/04-networking`, reading the zone name and resource group from
04's state through `terraform_remote_state`. Apply 04 first; destroy this
exercise before 04.

## What is built

**Phase 1** (always):

- Resource group `rg-az104-appservice`
- App Service plan `asp-az104-web`, Linux, **S1 Standard**
- Web app: HTTPS only, always on, PHP 8.2 (chosen only because it serves
  static files from `wwwroot` with no build step)
- Deployment slot `staging`
- CPU-based autoscale on the plan: 1-2 instances, out above 70%, in below 25%
- Storage account and a private container for App Service backups

**Phase 2** (`enable_custom_domain = true`):

- Apex A record, `www` CNAME, and `asuid` / `asuid.www` TXT records
- Hostname bindings for both names
- Free Azure-managed certificates, bound with SNI SSL

## Why S1

Deployment slots, autoscale rules and backup all require Standard or
higher. F1 (Free) has none of them; B1 (Basic) has none of them either.
S1 is the cheapest tier that does, at roughly EUR 0.09/hour - so this
exercise is deployed, demonstrated, documented and destroyed in one
session.

## Two things are deliberately not in Terraform

- **The backup schedule.** App Service backup needs a storage SAS token;
  generating one here would write a credential into the state file and
  recreate it on every expiry. Terraform owns the storage account and
  container, the schedule is configured in the portal, and
  `lifecycle { ignore_changes = [backup] }` keeps it from showing as drift.
- **The slot swap and the zip deployments.** Those are actions, not
  infrastructure.

## Run it

### Phase 1

    cd terraform/exercises/03c-app-service
    cp terraform.tfvars.example terraform.tfvars
    # edit: app_name, backup_storage_account_name, the two state_* values

    terraform init `
      -backend-config="resource_group_name=<from bootstrap output>" `
      -backend-config="storage_account_name=<from bootstrap output>"
    terraform apply        # 7 to add

Deploy both slots and swap:

    $app = "<app_name>"
    Compress-Archive -Path app\production\index.html -DestinationPath prod.zip -Force
    az webapp deploy -g rg-az104-appservice -n $app --src-path prod.zip --type zip

    Compress-Archive -Path app\staging\index.html -DestinationPath staging.zip -Force
    az webapp deploy -g rg-az104-appservice -n $app --slot staging --src-path staging.zip --type zip

    az webapp deployment slot swap -g rg-az104-appservice -n $app --slot staging --target-slot production

Then configure the backup in the portal: **Web app -> Backups -> Configure
custom backup**, pointing at the storage account and the
`appservice-backups` container.

### Phase 2

Read the app's inbound IP - it is not known until the app exists, and it
can change if the app is stopped for a long time and restarted on another
scale unit:

    az webapp show -g rg-az104-appservice -n <app_name> --query inboundIpAddress -o tsv

If that returns null (it is not always populated), `nslookup
<app_name>.azurewebsites.net` resolves to the same address.

Add to `terraform.tfvars`:

    enable_custom_domain = true
    app_inbound_ip       = "<that IP>"

    terraform apply        # 10 to add

A hostname binding can fail on the first attempt if Azure checks the
`asuid` TXT record before it has propagated. Wait a couple of minutes and
re-run `terraform apply`; the records are already in place. Managed
certificates then take 2-5 minutes each to issue.

## Cost notes

- App Service plan S1: ~EUR 0.09/hour (~EUR 60/month). The whole cost of
  the exercise
- Managed certificates: free
- Storage account: cents
- Destroy as soon as the exercise is documented

## What this demonstrates for AZ-104

- App Service plans and tiers, and choosing one by the features it unlocks
- Deployment slots and slot swaps
- Scale up (tier) versus scale out (instances), and autoscale rules on the plan
- App Service backup
- Custom domains: apex A records versus subdomain CNAMEs, and `asuid`
  TXT verification
- TLS bindings with Azure-managed certificates; SNI SSL versus IP-based SSL
