# Bicep and ARM templates - template basics

Source: `bicep/01-template-basics/`
Exam domain: Deploy and manage Azure compute resources (AZ-104) - the
"create and configure resources by using ARM templates and Bicep files"
objectives

This exercise is deliberately not Terraform. ARM and Bicep are their own
formats on the exam, and the questions usually show you a template and ask
what it does.

## What was built

One storage account and its blob service, deployed into their own resource
group (`rg-az104-bicep`) so the export step later produced a small,
readable template:

- `main.bicep` - 4 parameters (`baseName`, `location`, `storageSku`,
  `tags`), one variable for the derived name, a `StorageV2` account and a
  `blobServices` child resource, and 3 outputs
- `main.parameters.json` - overrides `storageSku` to `Standard_GRS`
- Deployed account: `staz104eb4tb2ppu4pwa` (the name is
  `st` + `baseName` + `uniqueString(resourceGroup().id)`)

## Notable decisions

- **Secure settings are fixed, not parameters.** TLS 1.2 minimum, HTTPS
  only and no public blob access live in the template body, so a caller
  can't weaken them by passing different values.
- **`@allowed` on the SKU.** An invalid value fails at validation, before
  anything is deployed.
- **`uniqueString(resourceGroup().id)` for the name.** Deterministic across
  redeployments, but unlikely to clash in Azure's global storage namespace.
  `baseName` is capped at 9 characters because the whole name must stay
  within 24.
- **`location` defaults to `resourceGroup().location`.** A convention, not
  a requirement - resources in a resource group can live in any region.
  The default keeps the template portable.
- **Soft delete, not lifecycle management.** The first attempt at the
  modification step used a `managementPolicies` rule that deletes blobs 7
  days after modification. That is the opposite of soft delete, which
  *retains* deleted blobs for 7 days. The working version sets
  `deleteRetentionPolicy` and `isVersioningEnabled` on the blob service.

## The six steps

| # | Step | What was used |
|---|---|---|
| 1 | Read the template and predict what it deploys | - |
| 2 | Modify it: add blob versioning and 7-day soft delete as a child resource | `az bicep build` to check it compiles |
| 3 | Preview the change | `az deployment group what-if` - 2 to create, SKU showing `Standard_GRS` from the parameter file |
| 4 | Deploy | `az deployment group create --name storage-baseline` |
| 5 | Export the resource group as an ARM template | `az group export` -> `exported/rg-az104-bicep.json` |
| 6 | Convert the exported ARM back to Bicep | `az bicep decompile` -> `exported/rg-az104-bicep.bicep` |

## What the export comparison showed

`main.bicep` is 57 lines and describes 2 resources. The decompiled export
describes **5**, and loses most of the design:

| Hand-written template | Decompiled export |
|---|---|
| 2 resources | 5 - `fileServices`, `queueServices` and `tableServices` exist on every StorageV2 account whether you declare them or not |
| 4 parameters with descriptions, defaults and `@allowed` | 1 generated parameter (`storageAccounts_staz104..._name`) with no default, so a deployment fails without it |
| `location: resourceGroup().location` | `location: 'swedencentral'` hard-coded |
| Only the properties that matter | Every default Azure filled in: `networkAcls`, `encryption`, `cors`, `staticWebsite`, `allowCrossTenantReplication`, `allowPermanentDelete` |
| API version `2023-05-01`, chosen | API version `2026-04-01` - the export uses the provider's current version, not the one deployed with |
| - | A `sku` block on each child service, which those types don't accept as input - the decompiled file would error or warn on redeploy |

Two details worth keeping:

- **File shares have soft delete on by default** (`shareDeleteRetentionPolicy`
  showed 7 days, enabled, without being asked for), while blob soft delete
  had to be turned on explicitly.
- **Deployment mode was `Incremental`**, the default: resources not in the
  template are left alone. `Complete` mode deletes them.

The conclusion: export and decompile are for capturing what someone built
in the portal so it can be brought under code. The output is a starting
point that needs cleaning, not a finished template.

## Verification in the Azure portal

| # | Screenshot | What it shows |
|---|---|---|
| 1 | `screenshots/01-deployment-history.png` | `storage-baseline` in the resource group's Deployments blade - ARM keeps deployment history, which Terraform has no equivalent of |
| 2 | `screenshots/02-deployment-inputs-outputs.png` | The deployment's Inputs (including `Standard_GRS`) and Outputs |
| 3 | `screenshots/03-export-template-blade.png` | Resource group -> Automation -> Export template, the portal path for step 5 |
| 4 | `screenshots/04-storage-replication.png` | Replication showing `Standard_GRS` - the parameter file overriding the template default |
| 5 | `screenshots/05-blob-data-protection.png` | Versioning enabled and 7-day blob soft delete - the step 2 modification |

## What this demonstrates for AZ-104

- Interpreting a Bicep template: parameters, decorators, variables,
  resources, child resources, outputs and API versions
- Modifying a template and checking it with `az bicep build`
- Previewing with `what-if` and deploying with `az deployment group create`
- Deployment history and deployment modes (Incremental vs Complete)
- Exporting a resource group as an ARM template, in the CLI and the portal
- Converting ARM JSON to Bicep with `az bicep decompile`, and why the
  result needs cleanup
- Blob soft delete vs lifecycle management, and blob vs file share defaults
