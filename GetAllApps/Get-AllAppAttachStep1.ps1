# Connect to Azure
Connect-AzAccount
Import-Module Az.DesktopVirtualization

# You can define multiple resource groups here by separating them with commas inside an array.
# Example: $resourceGroup = @("rg-avd-sam-uks-pool-compute","rg-avd-din-uks-service-obj","rg-avd-nut-uks-service-obj"
$resourceGroup = "<Name of the Resource group>"
$apps = Get-AzWvdAppAttachPackage -ResourceGroupName $resourceGroup

$export = foreach ($app in $apps) {
    $hostpools = ($app.HostPoolReference | ForEach-Object { ($_ -split '/')[-1] }) -join ';'

    $roleAssignments = Get-AzRoleAssignment -Scope $app.Id -RoleDefinitionName "Desktop Virtualization User" -ErrorAction SilentlyContinue
    $usergroupIds = ($roleAssignments | Select-Object -ExpandProperty ObjectId) -join ';'

    [PSCustomObject]@{
        app_name                        = $app.Name
        path                            = $app.ImagePath
        location                        = $app.Location
        resourcegroup_publish           = $app.ResourceGroupName
        hostpool_assign                 = $hostpools
        hostpool_packagepull            = ""   # intentionally empty
        resourcegroup_hostpool_packagepull = "" # intentionally empty
        usergroup_assign_ids            = $usergroupIds
        ImagePackageFamilyName          = $app.ImagePackageFamilyName
        ImagePackageApplication         = $app.ImagePackageApplication
        ImageVersion                    = $app.ImageVersion
        ImageIsActive                   = $app.ImageIsActive
        SystemDataCreatedAt             = $app.SystemDataCreatedAt
    }
}

$export | Export-Csv -Path "C:\Temp\AppAttachApps_Fast.csv" -NoTypeInformation
