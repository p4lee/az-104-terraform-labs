param storageAccounts_staz104eb4tb2ppu4pwa_name string

resource storageAccounts_staz104eb4tb2ppu4pwa_name_resource 'Microsoft.Storage/storageAccounts@2026-04-01' = {
  kind: 'StorageV2'
  location: 'swedencentral'
  name: storageAccounts_staz104eb4tb2ppu4pwa_name
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Allow'
      ipRules: []
      ipv6Rules: []
      virtualNetworkRules: []
    }
    supportsHttpsTrafficOnly: true
  }
  sku: {
    name: 'Standard_GRS'
    tier: 'Standard'
  }
  tags: {
    domain: 'bicep'
    project: 'az-104-portfolio'
  }
}

resource storageAccounts_staz104eb4tb2ppu4pwa_name_default 'Microsoft.Storage/storageAccounts/blobServices@2026-04-01' = {
  parent: storageAccounts_staz104eb4tb2ppu4pwa_name_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      days: 7
      enabled: true
    }
    isVersioningEnabled: true
    staticWebsite: {
      enabled: false
    }
  }
  sku: {
    name: 'Standard_GRS'
    tier: 'Standard'
  }
}

resource Microsoft_Storage_storageAccounts_fileServices_storageAccounts_staz104eb4tb2ppu4pwa_name_default 'Microsoft.Storage/storageAccounts/fileServices@2026-04-01' = {
  parent: storageAccounts_staz104eb4tb2ppu4pwa_name_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    protocolSettings: {
      smb: {}
    }
    shareDeleteRetentionPolicy: {
      days: 7
      enabled: true
    }
  }
  sku: {
    name: 'Standard_GRS'
    tier: 'Standard'
  }
}

resource Microsoft_Storage_storageAccounts_queueServices_storageAccounts_staz104eb4tb2ppu4pwa_name_default 'Microsoft.Storage/storageAccounts/queueServices@2026-04-01' = {
  parent: storageAccounts_staz104eb4tb2ppu4pwa_name_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Storage_storageAccounts_tableServices_storageAccounts_staz104eb4tb2ppu4pwa_name_default 'Microsoft.Storage/storageAccounts/tableServices@2026-04-01' = {
  parent: storageAccounts_staz104eb4tb2ppu4pwa_name_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}
