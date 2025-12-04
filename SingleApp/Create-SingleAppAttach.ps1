<#
.SYNOPSIS
    Automates Azure Virtual Desktop App Attach lifecycle for a single application.

.DESCRIPTION
    This script connects to Azure and Microsoft Graph, imports App Attach package
    information from a host pool, publishes the app into a chosen resource group,
    and assigns it to one or more host pools and user groups. Optional sections
    (commented out) allow unassigning host pools, unassigning user groups, and
    removing the App Attach app entirely.

.REQUIREMENTS
    - Az.DesktopVirtualization module
    - Microsoft.Graph module
    - Azure account with permissions to publish App Attach apps and assign groups
    - Prerequisites documented at:
      https://learn.microsoft.com/en-us/azure/virtual-desktop/app-attach-setup?tabs=powershell#prerequisites

.NOTES
    - Best practice: separate resource groups for host pools, session hosts,
      networking, storage, and monitoring.
    - Multiple host pools and user groups can be specified as comma-separated lists.
#>

Connect-AzAccount
Connect-MgGraph -Scopes 'Group.Read.All'
Import-Module Az.DesktopVirtualization

$app_name = <Application name>
$path = <Path to the CIM, VHDX, or AppV package file>
$location = <Azure region>
$hostpool_packagepull = <Host pool used to pull package info>
$resourcegroup_hostpool_packagepull = <Resource group of the Host pool>
$resourcegroup_publish = <Resource group where the App Attach app object will reside>
$hostpool_assign = <Comma-separated list of host pools to assign>
$usergroup_assign = <Comma-separated list of user groups to assign>

# Parameters to fetch package properties from the host pool and resource group
$parameters_package = @{
    HostPoolName      = $hostpool_packagepull
    ResourceGroupName = $resourcegroup_hostpool_packagepull
    Path              = $path
}

$app = Import-AzWvdAppAttachPackageInfo @parameters_package

# Verify the imported package info.
$app | Format-List *

# Parameters to publish the App Attach app
$parameters_publish = @{
    Name                          = $app_name
    ResourceGroupName             = $resourcegroup_publish # Resource group where the app object will reside.
    Location                      = $location
    FailHealthCheckOnStagingFailure = "NeedsAssistance"
    ImageIsRegularRegistration    = $false
    ImageDisplayName              = $app_name
    ImageIsActive                 = $true
}

# Create the App Attach app
New-AzWvdAppAttachPackage -AppAttachPackage $app @parameters_publish

# Parameters to validate the newly created App Attach app
$parameters_fetch = @{
    Name              = $app_name
    ResourceGroupName = $resourcegroup_publish
}

# Fetch and display key properties of the published app
Get-AzWvdAppAttachPackage @parameters_fetch | 
    Format-List Name, ImagePackageApplication, ImagePackageFamilyName, ImagePath, ImageVersion, ImageIsActive, ImageIsRegularRegistration, SystemDataCreatedAt

# Assign hostpool(s) to an Appattach app
$hostpoolIds = @()
foreach ($hostpoolName in $hostpool_assign) {
    $hostpoolIds += (Get-AzWvdHostPool | ? Name -eq $hostpoolName).Id
}

$parameters_hostpool_assign = @{
    Name = $app_name
    ResourceGroupName = $resourcegroup_publish
    HostPoolReference = $hostpoolIds
}

Update-AzWvdAppAttachPackage @parameters_hostpool_assign

# Assign user groups to the Appattach app
$UsergroupIds = @()

foreach ($group in $usergroup_assign) {
   $usergroupIds += (Get-MgGroup -Search "DisplayName:$group" -ConsistencyLevel: eventual).Id
}

$appAttachPackage = Get-AzWvdAppAttachPackage -Name $app_name -ResourceGroupName $resourcegroup_publish

foreach ($groupId in $usergroupIds) {
   New-AzRoleAssignment -ObjectId $groupId -RoleDefinitionName "Desktop Virtualization User" -Scope $appAttachPackage.Id
}


## --------------------- Start [Unassign hostpools from Appattach app] --------------------- ##
# $parameters_hostpool_assign = @{
#    Name = $app_name
#    ResourceGroupName = $resourcegroup_publish
#    HostPoolReference = @()
# }
# Update-AzWvdAppAttachPackage @parameters_hostpool_assign
## --------------------- End [Unassign hostpools from Appattach app] ----------------------- ##

## --------------------- Start [Unassign usergroups from Appattach app] -------------------- ##
# $appAttachPackage = Get-AzWvdAppAttachPackage -Name $app_name -ResourceGroupName $resourcegroup_publish

# foreach ($groupId in $usergroupIds) {
#   Remove-AzRoleAssignment -ObjectId $groupId -RoleDefinitionName "Desktop Virtualization User" -Scope $appAttachPackage.Id
# }
## --------------------- End [Unassign usergroups from Appattach app] ---------------------- ##

## --------------------- Start [Remove Appattach app] -------------------------------------- ##
# Remove-AzWvdAppAttachPackage -Name $app_name -ResourceGroupName $resourcegroup_publish
## --------------------- End [Remove Appattach app] ---------------------------------------- ##
