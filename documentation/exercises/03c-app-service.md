# Exercise 03c - App Service (slots, autoscale, backup, custom domain)

Terraform source: `terraform/exercises/03c-app-service/`
Exam domain: Deploy and manage Azure compute resources (20-25% of AZ-104)

## What was built

**Phase 1 - the app**

- Resource group `rg-az104-appservice`
- App Service plan `asp-az104-web`: Linux, **S1 Standard**
- Web app `app-az104-cclab`: HTTPS only, always on, PHP 8.2 stack
- Deployment slot `staging`
- CPU-based autoscale on the **plan**: 1-2 instances, out above 70%, in below 25%
- Storage account `stappbackupcclab` with a private `appservice-backups` container

**Phase 2 - custom domain and TLS** (gated behind `enable_custom_domain`)

- An A record for the apex `cloud-consult-lab.site` -> the app's inbound IP
- A CNAME for `www` -> `app-az104-cclab.azurewebsites.net`
- `asuid` and `asuid.www` TXT records carrying the domain verification ID
- Hostname bindings for both names
- Free Azure-managed certificates for both, bound with **SNI SSL**

The DNS records live in exercise 04's zone; this exercise only adds records
to it, reading the zone name and resource group through
`terraform_remote_state`.

## Notable decisions

- **S1 Standard, not Free or Basic.** Deployment slots, autoscale rules and
  backup all require Standard or higher. F1 has none of them; B1 has
  neither slots, autoscale nor backup. This is the whole reason the
  exercise costs money, so it was built, demonstrated and destroyed in one
  session.
- **Autoscale targets the plan, not the app.** Instances belong to the
  plan, and every app and slot on it shares them. That is also why the
  staging slot costs nothing extra.
- **Backup is configured in the portal, not in Terraform.** App Service
  backup needs a storage SAS token; generating one in Terraform would write
  a credential into the state file and recreate it on every expiry.
  Terraform owns the storage account and container,
  `lifecycle { ignore_changes = [backup] }` keeps the hand-made schedule
  from showing up as drift.
- **The apex needs an A record; the subdomain can be a CNAME.** DNS forbids
  a CNAME at the zone root (it would collide with the SOA and NS records
  that must live there), and Azure DNS alias records don't target App
  Service. So the apex pins an IP read from the running app, while `www`
  points at the hostname and keeps working if Azure moves the app.
- **SNI SSL, not IP-based SSL.** Many certificates share one front-end IP
  and the client names the host it wants during the TLS handshake.
  IP-based SSL dedicates an IP per certificate and costs extra.

## Terraform outputs

```
resource_group_name   = "rg-az104-appservice"
app_default_hostname  = "app-az104-cclab.azurewebsites.net"
slot_default_hostname = "app-az104-cclab-staging.azurewebsites.net"
backup_storage_account = "stappbackupcclab"
custom_domain_urls    = [
  "https://cloud-consult-lab.site",
  "https://www.cloud-consult-lab.site",
]
```

## The slot swap

Production and staging were deployed with visibly different pages (a green
"PRODUCTION" banner and an orange "STAGING" one), both zipped from
`app/production` and `app/staging`:

    az webapp deploy -g rg-az104-appservice -n app-az104-cclab --src-path prod.zip --type zip
    az webapp deploy -g rg-az104-appservice -n app-az104-cclab --slot staging --src-path staging.zip --type zip

Then:

    az webapp deployment slot swap -g rg-az104-appservice -n app-az104-cclab --slot staging --target-slot production

After the swap the production URL served the orange page and the staging URL
the green one - the slots exchanged running instances, with no
redeployment. That is what makes a swap near-instant and reversible: swap
again and you are back.

## Why the inbound IP has to be read at apply time

`app-az104-cclab.azurewebsites.net` resolved to **51.12.73.239** via
`waws-prod-sec-053`, an App Service scale unit. That IP belongs to a
**shared front end**, not to this app - which is exactly why the `asuid`
TXT record exists: pointing an A record at a shared IP proves nothing about
ownership, so Azure demands separate proof before binding the hostname.

It also means an apex A record pins an address Azure may change, for
example if the app moves scale unit after a long stop. Production setups
avoid that by putting Front Door or Traffic Manager in front, or by using
an alias record to a resource with a stable IP.

## Problems hit along the way

**1. `Output refers to sensitive values`.**
The provider marks `custom_domain_verification_id` sensitive, so the root
output had to be annotated `sensitive = true` and read with
`terraform output -raw`. It is not really a secret - it is published in a
public TXT record - but Terraform refuses to surface it unannotated.

**2. The backup block showed as drift.**
With backup configured in the portal and absent from the configuration,
the first phase-2 plan said "1 to change" and wanted to **remove** it.
Fixed with `ignore_changes = [backup]`.

**3. A near-miss worth recording.**
While pasting phase 2 in, `main.tf` briefly ended up containing only the
phase 2 block - twice - with all of phase 1 gone. Terraform refused to
parse it because of the duplicate resource names, which is the only reason
it was caught: had the paste been clean, `terraform plan` would have shown
**7 to destroy** against resources that exist in Azure. The lesson is to
read a plan's destroy count before approving it, every time. Phase 1 was
recovered from the previous commit.

**4. The subscription was disabled mid-exercise.**
The free trial credit ran out between phases. A disabled subscription is
read-only: even `az webapp show` failed with
`ReadOnlyDisabledSubscription`, and after upgrading to pay-as-you-go the
web apps stayed stopped until started explicitly. Nothing bills while a
subscription is disabled, but everything resumes billing on upgrade.

## Verification in the Azure portal

| # | Screenshot | What it shows |
|---|---|---|
| 1 | `screenshots/01-app-service-plan.png` | The S1 Linux plan and the apps on it |
| 2 | `screenshots/02-webapp-overview.png` | Web app running, HTTPS only, default hostname |
| 3 | `screenshots/03-deployment-slots.png` | Production and staging slots |
| 4 | `screenshots/04-before-swap-production.png` | The green PRODUCTION page on the production URL |
| 5 | `screenshots/05-before-swap-staging.png` | The orange STAGING page on the staging URL |
| 6 | `screenshots/06-swap-dialog.png` | The swap dialog: source staging, target production |
| 7 | `screenshots/07-after-swap-production.png` | The production URL now serving the orange page |
| 8 | `screenshots/08-autoscale-rules.png` | Autoscale on the plan: 1-2 instances, 70% / 25% |
| 9 | `screenshots/09-scale-up-tiers.png` | The Scale up blade - which features each tier includes |
| 10 | `screenshots/10-backup-configured.png` | The backup schedule and its storage container |
| 11 | `screenshots/11-custom-domains.png` | Both hostnames bound and secured |
| 12 | `screenshots/12-certificates.png` | The two Azure-managed certificates |
| 13 | `screenshots/13-browser-apex-https.png` | `https://cloud-consult-lab.site` with a valid certificate |

The matching DNS records are in exercise 04's screenshot
`05-dns-zone-records.png`: NS, SOA, the apex A record, the `www` CNAME and
both `asuid` TXT records.

## Cost notes

- App Service plan S1: about EUR 0.09/hour, roughly EUR 60/month. By far the
  most expensive thing built in this portfolio
- Managed certificates: free
- Storage account: cents
- Destroyed immediately after documenting

## What this demonstrates for AZ-104

- Creating an App Service plan and web app, and choosing a tier by the
  features it unlocks
- Deployment slots and slot swaps
- Scaling: manual scale up (tier) versus scale out (instances), and
  autoscale rules on the plan
- App Service backup and why its SAS requirement keeps it out of Terraform
- Custom domains: apex A records versus subdomain CNAMEs, and `asuid` TXT
  verification
- TLS bindings with Azure-managed certificates, SNI SSL versus IP-based SSL
- Reading an apply plan carefully, especially the destroy count
