# Connect to Graph
Connect-MgGraph -Scopes 'Group.Read.All'

$apps = Import-Csv "C:\Temp\AppAttachApps_Fast.csv"
$groupCache = @{}

$enriched = foreach ($app in $apps) {
    $ids = $app.usergroup_assign_ids -split ';'
    $names = @()

    foreach ($id in $ids) {
        if (-not [string]::IsNullOrWhiteSpace($id)) {
            if (-not $groupCache.ContainsKey($id)) {
                try {
                    $grp = Get-MgGroup -GroupId $id -ErrorAction SilentlyContinue
                    $groupCache[$id] = $grp.DisplayName
                } catch {
                    $groupCache[$id] = $null
                }
            }
            if ($groupCache[$id]) { $names += $groupCache[$id] }
        }
    }

    [PSCustomObject]@{
        app_name                        = $app.app_name
        path                            = $app.path
        location                        = $app.location
        resourcegroup_publish           = $app.resourcegroup_publish
        hostpool_assign                 = $app.hostpool_assign
        hostpool_packagepull            = ""   # intentionally empty
        resourcegroup_hostpool_packagepull = "" # intentionally empty
        usergroup_assign                = ($names -join ';')
        ImagePackageFamilyName          = $app.ImagePackageFamilyName
        ImagePackageApplication         = $app.ImagePackageApplication
        ImageVersion                    = $app.ImageVersion
        ImageIsActive                   = $app.ImageIsActive
        SystemDataCreatedAt             = $app.SystemDataCreatedAt
    }
}

$enriched | Export-Csv -Path "C:\Temp\AppAttachApps_Complete.csv" -NoTypeInformation
