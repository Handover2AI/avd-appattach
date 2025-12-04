# Azure Virtual Desktop App Attach Automation

This repository contains a PowerShell script to automate the lifecycle of a single **App Attach** application in Azure Virtual Desktop (AVD).

## Features

- Connects to Azure and Microsoft Graph
- Imports App Attach package information from a host pool
- Publishes the app into a specified resource group
- Assigns the app to one or more host pools
- Assigns the app to one or more Azure AD user groups
- Optional sections (commented out) for:
  - Unassigning host pools
  - Unassigning user groups
  - Removing the App Attach app

## Prerequisites

- [Az.DesktopVirtualization](https://learn.microsoft.com/powershell/azure/new-azureps-module-az) PowerShell module
- [Microsoft.Graph](https://learn.microsoft.com/powershell/microsoftgraph/overview) PowerShell module
- Azure account with permissions to publish App Attach apps and assign user groups
- AVD App Attach prerequisites documented [here](https://learn.microsoft.com/en-us/azure/virtual-desktop/app-attach-setup?tabs=powershell#prerequisites)

## Usage

1. Clone this repository or download the script.
2. Update the variables in the script:
   - `app_name` – Application name/display name
   - `path` – Path to the CIM, VHDX, or AppV package file
   - `location` – Azure region
   - `hostpool_packagepull` – Host pool used to pull package info. This is the Host pool where session hosts have access to the file share. This could be be the same host pool as defined in `$hostpool_assign`
   - `resourcegroup_hostpool_packagepull` – Resource group of the host pool
   - `resourcegroup_publish` – Resource group where the App Attach app object will reside. This is often the same as the host pool resource group
   - `hostpool_assign` – Comma-separated list of host pools to assign. See Notes section below
   - `usergroup_assign` – Comma-separated list of user groups to assign
3. Run the script in PowerShell:
   ```powershell
   Connect-AzAccount
   Connect-MgGraph -Scopes 'Group.Read.All'
   .\Create-SingleAppAttach.ps1

## Example 

- `$app_name` = "Avaya-One-X Agent 2.5.60624-New"
- `$path` = "\\storageaccountname.file.core.windows.net\appattach\Images\AppV\Avaya-One-X Agent 2.5.60624\Avaya-One-X Agent 2.5.appv"
- `$location` = "westeurope"
- `$hostpool_packagepull` = "multi-session-pool-sam-uks-001"
- `$resourcegroup_hostpool_packagepull` = "rg-avd-sam-uks-service-obj"
- `$resourcegroup_publish` = "rg-avd-sam-uks-service-obj"
- `$hostpool_assign` = "multi-session-pool-sam-uks-001","multi-session-pool-ind-uks-001"
- `$usergroup_assign` = "APP-KK-AVD-SAM-Pooled-Desktop-Users","APP-KK-AVD-IND-Pooled-Desktop-Users"
- `$ImageIsRegularRegistration` = $false means on-demand registration; set to $true to register at logon.
- `$ImageIsActive` = $true keeps the app active; set to $false to stage but not activate.
- `$FailHealthCheckOnStagingFailure` = NeedsAssistance is what you will see in session host vm's health status for AppAttach health check. Other options are "Unhealthy" and "Donotfail".

## Notes

- Assignments overwrite existing ones. To update, specify the full list of host pools or groups.
- Commented sections in the script can be enabled to unassign or remove apps.
- Best practice in enterprise AVD deployments is to separate resource groups for host pools, session hosts, networking, storage, and monitoring.
- `$app | Format-List *` - If multiple package objects are returned (e.g., x64 and x86 versions), use the PackageFullName parameter to select the correct package.
  ```powershell
  $app = Import-AzWvdAppAttachPackageInfo @parameters_package | Where-Object { $_.ImagePackageFullName -like "*$packageFullName*" }

