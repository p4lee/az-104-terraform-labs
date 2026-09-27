# Bicep and ARM templates - template basics

Exam domain: Deploy and manage Azure compute resources (AZ-104) - the
"create and configure resources by using ARM templates and Bicep files"
objectives: interpret a template, modify and deploy one, export a
deployment as a template, and convert ARM to Bicep.

This folder is deliberately **not** Terraform. Bicep and ARM are their own
formats on the exam, and you need to be able to read them.

## Files

| File | What it is |
|---|---|
| `main.bicep` | The template: one storage account, with parameters, a variable and outputs |
| `main.parameters.json` | A parameter file that overrides `storageSku` to `Standard_GRS` |
| `exported/` | Where the exported ARM template and its decompiled Bicep go (step 5-6) |

## Prerequisites

    az bicep install     # or: az bicep upgrade
    az bicep version

Everything is deployed into its own resource group so the export step
produces a small, readable template:

    az group create -n rg-az104-bicep -l swedencentral

## Step 1 - read the template

Before running anything, answer these from `main.bicep` alone:

1. What resource is created, and what is its name at deploy time?
2. Which values can the caller change, and which are fixed?
3. What happens if you pass `storageSku = 'Premium_LRS'`?
4. Why is `location` defaulted to `resourceGroup().location` instead of a
   hard-coded region?

Key pieces of syntax:

- `param` - an input. Decorators like `@allowed`, `@minLength` and
  `@description` are validated before anything is deployed.
- `var` - computed inside the template; callers can't override it.
- `resource <symbolic-name> '<type>@<api-version>'` - the resource itself.
  The API version matters: it decides which properties exist.
- `output` - values handed back after deployment, e.g. to a pipeline or
  another template.

## Step 2 - modify it

Add blob versioning and 7-day soft delete for blobs. In Bicep this is a
**child resource** of the storage account, `blobServices@2023-05-01` named
`default`.

Try it yourself first. One way to write it:

```bicep
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
  properties: {
    isVersioningEnabled: true
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}
```

`parent: storage` is the readable way to express the parent-child link.
The alternative, `name: '${storage.name}/default'`, is what you'll see in
older ARM templates and in decompiled output.

## Step 3 - preview with what-if

    az deployment group what-if `
      --resource-group rg-az104-bicep `
      --template-file main.bicep `
      --parameters main.parameters.json

`what-if` is the ARM equivalent of `terraform plan`. Read the output: it
marks resources as Create, Modify, Delete, Ignore or NoChange.

## Step 4 - deploy

    az deployment group create `
      --resource-group rg-az104-bicep `
      --template-file main.bicep `
      --parameters main.parameters.json `
      --name storage-baseline

Check the outputs:

    az deployment group show -g rg-az104-bicep -n storage-baseline --query properties.outputs

Deployments are named and kept in history, which is something Terraform has
no direct equivalent of:

    az deployment group list -g rg-az104-bicep -o table

## Step 5 - export the resource group as an ARM template

    az group export --name rg-az104-bicep > exported/rg-az104-bicep.json

In the portal the same thing is under **Resource group -> Automation ->
Export template**. This is how you capture something that was created by
hand in the portal.

Look at what you get: resource names become parameters, secrets are
stripped, and the file is far longer than the Bicep it came from.

## Step 6 - convert ARM to Bicep and compare

    az bicep decompile --file exported/rg-az104-bicep.json

This writes `exported/rg-az104-bicep.bicep`. Compare it with `main.bicep`:

- Generated parameter names like `storageAccounts_st..._name`
- No `@allowed`, `@description` or sensible defaults
- Values hard-coded where your template used `uniqueString()`
- Warnings about properties the decompiler couldn't map

The lesson: decompiling gives you a working starting point, not a finished
template. That's exactly what the exam objective "convert ARM to Bicep"
is about.

## Cleanup

    az group delete -n rg-az104-bicep --yes --no-wait

## What this demonstrates for AZ-104

- Interpreting an ARM/Bicep template: parameters, variables, resources,
  outputs, API versions
- Modifying a template (adding a child resource)
- Previewing with `what-if` and deploying with `az deployment group create`
- Deployment history at resource group scope
- Exporting a resource group as an ARM template
- Converting ARM JSON to Bicep with `az bicep decompile`, and why the
  result needs cleaning up
