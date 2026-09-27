@description('Base name used to derive resource names. Kept short because storage account names are limited to 24 lowercase characters.')
@minLength(3)
@maxLength(9)
param baseName string = 'az104'

@description('Region for the resources. Defaults to the resource group location - the usual pattern, and it keeps the template portable.')
param location string = resourceGroup().location

@description('Storage redundancy. Constrained on purpose: a typo fails at validation instead of deploying the wrong thing.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
])
param storageSku string = 'Standard_LRS'

@description('Tags applied to everything this template creates.')
param tags object = {
  project: 'az-104-portfolio'
  domain: 'bicep'
}

// uniqueString() hashes the resource group id into 13 characters. It's
// deterministic, so redeploying gives the same name, but it's unlikely to
// clash in Azure's global storage namespace.
var storageAccountName = toLower('st${baseName}${uniqueString(resourceGroup().id)}')

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }

  
}
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



output storageAccountName string = storage.name
output storageAccountId string = storage.id
output primaryBlobEndpoint string = storage.properties.primaryEndpoints.blob
