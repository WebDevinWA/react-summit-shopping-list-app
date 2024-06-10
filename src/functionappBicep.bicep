@description('Location for all resources')
param location string = resourceGroup().location

@description('Suffix for function app and storage account. For training purposes, use your UW Net ID')
param appNameSuffix string

@description('The name of the function app that you wish to create')
var appName = 'fn-${appNameSuffix}'

@description('The language worker runtime to load in the function app')
var runtime = 'node'

@description('An object describing the App Service Plan. For training purposes, we should use the Y1/Dynamic app service plan.')
var appServicePlan = {
  name: 'FunctionPlan${appNameSuffix}'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stor${replace(appNameSuffix, '-', '')}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

resource plan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'ASP-${appNameSuffix}'
  location: location
  kind: 'functionapp'
  sku: appServicePlan.sku
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: appName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: runtime
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: appName
        }
      ]
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
    }
    httpsOnly: true
  }
}

/* resource itemListFunction 'Microsoft.Web/sites/functions@2023-01-01' = {
  parent: functionApp
  name: 'itemlists'
  properties: {
    files: {
      'host.json': loadTextContent('host.json')
      'package.json': loadTextContent('package.json')
      'package-lock.json': loadTextContent('package-lock.json')
      'itemlists.js': loadTextContent('src/functions/itemlists.js')
    }
  }
} */
