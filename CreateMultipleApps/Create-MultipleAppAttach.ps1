# Connect to Azure
Connect-AzAccount #-DeviceCode
Connect-MgGraph -Scopes 'Group.Read.All'
Import-Module Az.DesktopVirtualization

# Import CSV with app definitions
$apps = Import-Csv "C:\Temp\AppAttachApps_Complete.csv"

foreach ($row in $apps) {
    Write-Output "Processing app: $($row.app_name)"
    
    if (-not $row.app_name) { continue }  # skip blank rows
    
    # Parameters to fetch package properties
    $parameters_package = @{
        HostPoolName      = $row.hostpool_packagepull
        ResourceGroupName = $row.resourcegroup_hostpool_packagepull
        Path              = $row.path
    }

    $app = Import-AzWvdAppAttachPackageInfo @parameters_package

    # Optional: check if multiple package objects returned
    $app | Format-List *

    # Parameters to publish the App Attach app
    $parameters_publish = @{
        Name                          = $row.app_name
        ResourceGroupName             = $row.resourcegroup_publish
        Location                      = $row.location
        FailHealthCheckOnStagingFailure = "NeedsAssistance"
        ImageIsRegularRegistration    = $false
        ImageDisplayName              = $row.app_name
        ImageIsActive                 = $true
    }

    # Create App Attach app
    $newApp = New-AzWvdAppAttachPackage -AppAttachPackage $app @parameters_publish

    # Validate newly created app
    $parameters_fetch = @{
        Name              = $row.app_name
        ResourceGroupName = $row.resourcegroup_publish
    }

    Get-AzWvdAppAttachPackage @parameters_fetch |
        Format-List Name, ImagePackageApplication, ImagePackageFamilyName, ImagePath, ImageVersion, ImageIsActive, ImageIsRegularRegistration, SystemDataCreatedAt

   # Assign hostpool(s) to an Appattach app
    if ($row.hostpool_assign) {
        $hostpoolIds = @()
        $hostpools = $row.hostpool_assign -split ';'
        foreach ($hp in $hostpools) {
            $hostpoolIds += (Get-AzWvdHostPool | Where-Object Name -eq $hp).Id
    }

    $parameters_hostpool_assign = @{
        Name              = $row.app_name
        ResourceGroupName = $row.resourcegroup_publish
        HostPoolReference = $hostpoolIds
    }

    Update-AzWvdAppAttachPackage @parameters_hostpool_assign
    }

    # Assign user groups to the Appattach app
    if ($row.usergroup_assign) {
        $usergroupIds = @()

        # Split the semicolon-separated list from the CSV
        $groups = $row.usergroup_assign -split ';'
        foreach ($grp in $groups) {
            Write-Output "Resolving user group: $grp"
            $usergroupIds += (Get-MgGroup -Search "DisplayName:$grp" -ConsistencyLevel eventual).Id
        }

        # Fetch the App Attach package object
        $appAttachPackage = Get-AzWvdAppAttachPackage -Name $row.app_name -ResourceGroupName $row.resourcegroup_publish

        # Assign each group to the app
        foreach ($groupId in $usergroupIds) {
            Write-Output "Assigning $($row.app_name) to user group ID: $groupId"
            New-AzRoleAssignment -ObjectId $groupId `
                                 -RoleDefinitionName "Desktop Virtualization User" `
                                 -Scope $appAttachPackage.Id
        }
    }

    ## --------------------- Start [Unassign hostpools from Appattach app] --------------------- ##
    # To clear host pool assignments for a given app, set HostPoolReference to an empty array.
    # This removes all host pool associations.
    # Uncomment to use.

    # $parameters_hostpool_unassign = @{
    #     Name              = $row.app_name
    #     ResourceGroupName = $row.resourcegroup_publish
    #     HostPoolReference = @()
    # }
    # Update-AzWvdAppAttachPackage @parameters_hostpool_unassign
    ## --------------------- End [Unassign hostpools from Appattach app] ----------------------- ##


    ## --------------------- Start [Unassign usergroups from Appattach app] -------------------- ##
    # Fetch the App Attach package object
    # $appAttachPackage = Get-AzWvdAppAttachPackage -Name $row.app_name -ResourceGroupName $row.resourcegroup_publish

    # Loop through previously resolved user group IDs and remove role assignments
    # foreach ($groupId in $usergroupIds) {
    #     Remove-AzRoleAssignment -ObjectId $groupId `
    #                             -RoleDefinitionName "Desktop Virtualization User" `
    #                             -Scope $appAttachPackage.Id
    # }
    ## --------------------- End [Unassign usergroups from Appattach app] ---------------------- ##


    ## --------------------- Start [Remove Appattach app] -------------------------------------- ##
    # To delete the App Attach app object entirely:
    # Remove-AzWvdAppAttachPackage -Name $row.app_name -ResourceGroupName $row.resourcegroup_publish
    ## --------------------- End [Remove Appattach app] ---------------------------------------- ##

}
