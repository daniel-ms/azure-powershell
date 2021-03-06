﻿
function Get-AzureRmStorageAccount
{

  [CmdletBinding()]
  param(
    [string] [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)] $ResourceGroupName,
    [string] [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)] [alias("StorageAccountName")] $Name)
  BEGIN { 
    $context = Get-Context
	$client = Get-StorageClient $context
  }
  PROCESS {
    $getTask = $client.StorageAccounts.GetPropertiesAsync($ResourceGroupName, $name, [System.Threading.CancellationToken]::None)
	$sa = $getTask.Result
	$account = Get-StorageAccount $ResourceGroupName $Name
	Write-Output $account
  }
  END {}

}

function New-AzureRmStorageAccount
{
  [CmdletBinding()]
  param(
    [string] [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)] $ResourceGroupName,
    [string] [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)][alias("StorageAccountName")] $Name,
	[string] [Parameter(Position=2, ValueFromPipelineByPropertyName=$true)] $Location,
    [string] [Parameter(Position=3, ValueFromPipelineByPropertyName=$true)] $typeString)
  BEGIN { 
    $context = Get-Context
	$client = Get-StorageClient $context
  }
  PROCESS {
    $createParms = New-Object -Type Microsoft.Azure.Management.Storage.Models.StorageAccountCreateParameters
    if ($typeString -eq $null)
    {
      $Type = [Microsoft.Azure.Management.Storage.Models.AccountType]::StandardLRS
    }
    else
    {
      $Type = Parse-Type $typeString
	}

	$createParms.AccountType = $Type
	$createParms.Location = $Location
    $getTask = $client.StorageAccounts.CreateAsync($ResourceGroupName, $name, $createParms, [System.Threading.CancellationToken]::None)
	$sa = $getTask.Result
  }
  END {}

}

function Set-AzureRmStorageAccount
{
  [CmdletBinding()]
  param(
    [string] [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)] $ResourceGroupName,
    [string] [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)][alias("StorageAccountName")] $Name,
    [string] [Parameter(Position=2, ValueFromPipelineByPropertyName=$true)] $Type,
    [Hashtable[]] [Parameter(Position=3, ValueFromPipelineByPropertyName=$true)] $Tags)
  BEGIN { 
    $context = Get-Context
    $client = Get-StorageClient $context
  }
  PROCESS {
    $createParms = New-Object -Type Microsoft.Azure.Management.Storage.Models.StorageAccountUpdateParameters
    $createParms.AccountType = [Microsoft.Azure.Management.Storage.Models.AccountType]::StandardLRS
    $getTask = $client.StorageAccounts.UpdateAsync($ResourceGroupName, $Name, $createParms, [System.Threading.CancellationToken]::None)
    $sa = $getTask.Result
  }
  END {}
}


function Get-AzureRmStorageAccountKey
{
  [CmdletBinding()]
  param(
    [string] [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)] $ResourceGroupName,
    [string] [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)] [alias("StorageAccountName")] $Name)
  BEGIN {  
    $context = Get-Context
	$client = Get-StorageClient $context
  }
  PROCESS { 
    $getTask = $client.StorageAccounts.ListKeysAsync($ResourceGroupName, $name, [System.Threading.CancellationToken]::None)
	Write-Output $getTask.Result.StorageAccountKeys
  }
  END {}
}

function Remove-AzureRmStorageAccount
{

  [CmdletBinding()]
  param(
    [string] [Parameter(Position=0, ValueFromPipelineByPropertyName=$true)] $ResourceGroupName,
    [string] [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)] [alias("StorageAccountName")] $Name)
  BEGIN { 
    $context = Get-Context
	$client = Get-StorageClient $context
  }
  PROCESS {
    $getTask = $client.StorageAccounts.DeleteAsync($ResourceGroupName, $name, [System.Threading.CancellationToken]::None)
	$sa = $getTask.Result
  }
  END {}

}

function Get-Context
{
    [Microsoft.Azure.Commands.Common.Authentication.Models.AzureContext]$context = $null
    $profile = [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile
	if ($profile -ne $null)
	{
	  $context = $profile.Context
	}

	return $context
}

 function Parse-Type
 {
    param([string] $type)
    $type = $type.Replace("_", "")
    $returnSkuName = [System.Enum]::Parse([Microsoft.Azure.Management.Storage.Models.AccountType], $type)
    return $returnSkuName;
 }

function Get-StorageClient
{
  param([Microsoft.Azure.Commands.Common.Authentication.Models.AzureContext] $context)
  $factory = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::ClientFactory
  [System.Type[]]$types = [Microsoft.Azure.Commands.Common.Authentication.Models.AzureContext], [Microsoft.Azure.Commands.Common.Authentication.Models.AzureEnvironment+Endpoint]
  $method = [Microsoft.Azure.Commands.Common.Authentication.IClientFactory].GetMethod("CreateClient", $types)
  $closedMethod = $method.MakeGenericMethod([Microsoft.Azure.Management.Storage.StorageManagementClient])
  $arguments = $context, [Microsoft.Azure.Commands.Common.Authentication.Models.AzureEnvironment+Endpoint]::ResourceManager
  $client = $closedMethod.Invoke($factory, $arguments)
  return $client
}

function Get-StorageAccount {
  param([string] $resourceGroupName, [string] $name)
	$endpoints = New-Object PSObject -Property @{"Blob" = "https://$name.blob.core.windows.net/"}
  $sa = New-Object PSObject -Property @{"Name" = $name; "ResourceGroupName" = $resourceGroupName; 
	  "PrimaryEndpoints" = $endpoints
  }
  return $sa
}