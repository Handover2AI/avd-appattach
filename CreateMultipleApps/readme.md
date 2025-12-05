# Azure Virtual Desktop App Attach Automation for Multiple App

This script automates the **bulk creation and assignment of Azure Virtual Desktop (AVD) App Attach apps** using definitions stored in a CSV file. It is the companion to [Create-SingleAppAttach.ps1](https://github.com/Handover2AI/avd-appattach/tree/main/CreateSingleApp), but designed to process multiple apps in one run.

---

## 📑 Prerequisites

- Azure PowerShell module **Az.DesktopVirtualization**
- Microsoft Graph PowerShell module
- A valid CSV file (`AppAttachApps_Complete.csv`) containing app definitions
  - Either exported via the two‑step workflow ([Get-AllAppAttachStep1.ps1 and Get-AllAppAttachStep2.ps1](https://github.com/Handover2AI/avd-appattach/tree/main/GetAllApps))
    - Ensure that values are filled properly for:
      - `hostpool_packagepull`
      - `resourcegroup_hostpool_packagepull`
         > ⚠️ These two columns are intentionally left empty during export. You must fill them before running this script, otherwise package import will fail.
  - Or filled manually ($${\color{green}A}$$ $${\color{green}sample}$$ $${\color{green}CSV}$$ $${\color{green}file}$$ $${\color{green}is}$$ $${\color{green}part}$$ $${\color{green}of}$$ $${\color{green}the}$$ $${\color{green}repo}$$)
    - Manually creating the CSV file doesn't require filling values for `ImagePackageFamilyName`, `ImagePackageApplication`, `ImageVersion` `ImageIsActive`, and `SystemDataCreatedAt`

---

## 📂 CSV Schema

The script expects the following columns in `AppAttachApps_Complete.csv`:

| Column                          | Description                                                                 |
|---------------------------------|-----------------------------------------------------------------------------|
| `app_name`                      | Display name of the App Attach app                                          |
| `path`                          | Path to the CIM/VHDX/AppV package file                                      |
| `location`                      | Azure region where the app is published                                     |
| `resourcegroup_publish`         | Resource group where the App Attach app object will be created              |
| `hostpool_packagepull`          | Host pool name used to pull package info (must be filled before import)     |
| `resourcegroup_hostpool_packagepull` | Resource group of the host pool (must be filled before import)          |
| `hostpool_assign`               | Semicolon‑separated list of host pools to assign the app to                 |
| `usergroup_assign`              | Semicolon‑separated list of Azure AD group display names to assign the app  |
| `ImagePackageFamilyName`        | Package family name                                                         |
| `ImagePackageApplication`       | Application name inside the package                                         |
| `ImageVersion`                  | Version of the package                                                      |
| `ImageIsActive`                 | Whether the app is active (`True`/`False`)                                  |
| `SystemDataCreatedAt`           | Timestamp when the app object was created                                   |

---

## ⚙️ Script Workflow

1. **Connect to Azure and Graph**
   - Authenticates to Azure (`Connect-AzAccount`) and Microsoft Graph (`Connect-MgGraph`).

2. **Import CSV**
   - Reads `AppAttachApps_Complete.csv` into `$apps`.

3. **Loop through each row**
   - Skips blank rows.
   - Imports package info (`Import-AzWvdAppAttachPackageInfo`).
   - Publishes the App Attach app (`New-AzWvdAppAttachPackage`).
   - Validates creation (`Get-AzWvdAppAttachPackage`).

4. **Assign host pools**
   - Splits `hostpool_assign` into individual names.
   - Resolves host pool IDs.
   - Updates the app with host pool references (`Update-AzWvdAppAttachPackage`).

5. **Assign user groups**
   - Splits `usergroup_assign` into individual names.
   - Resolves group IDs via Graph (`Get-MgGroup`).
   - Creates role assignments (`New-AzRoleAssignment`).

6. **Optional operations (commented)**
   - Unassign host pools.
   - Unassign user groups.
   - Remove App Attach app entirely.

---

## ✅ Usage

```powershell
# Run the script
.\Create-MultipleAppAttach.ps1
```
---

## 📌 Notes
- Make sure that CSV file is located at C:\Temp\AppAttachApps_Complete.csv (or adjust the path).
- Make sure that `hostpool_packagepull` and `resourcegroup_hostpool_packagepull` are filled correctly.
- Make sure that you have permissions to create and assign App Attach apps in the specified resource groups.
- Blank rows in the CSV are skipped automatically.
- If `hostpool_packagepull` or `resourcegroup_hostpool_packagepull` are empty, package import will fail.
- User group resolution uses Graph search by display name. Ensure group names in the CSV match Azure AD exactly.
- The script includes commented sections for unassigning host pools, unassigning user groups, and removing apps if needed.
