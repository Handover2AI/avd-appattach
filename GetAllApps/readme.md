# Azure Virtual Desktop App Attach Export & Bulk Management

This repository provides scripts to **export existing App Attach apps** into CSV files and reuse them for **bulk creation and assignment**.

---

## 📑 Two-Step Export Workflow

To balance speed and completeness, we recommend a **two-step process**:

### ⚡ Step 1 – Fast Export (IDs only)
- **Script name:** `Get-AllAppAttachStep1.ps1`
- Quickly exports all App Attach apps in a resource group to a CSV.
- Includes:
  - App metadata (name, path, version, etc.)
  - Host pool assignments (names)
  - User group **IDs** (fast to collect, no Graph lookups)
- **Note:** Execution time depends on the number of App Attach apps in your environment. The more apps you have, the longer it will take to enumerate them.
- Output file: `AppAttachApps_Fast.csv`

### 🕵️ Step 2 – Enrichment (resolve IDs → names)
- **Script name:** `Get-AllAppAttachStep2.ps1`
- Reads the Step 1 CSV and enriches it by resolving user group IDs into **display names** via Microsoft Graph.
- Uses caching to avoid repeated Graph calls, but will still take longer than Step 1.
- Output file: `AppAttachApps_Complete.csv`

---

## ✅ Why This Matters

- **Performance vs completeness**  
  - Step 1 is fast and lightweight, suitable for quick inventory.  
  - Step 2 is slower but produces a human‑friendly CSV with group names.

- **Automation aid**  
  - The exported CSV can be used directly as input for your **bulk App Attach creation scripts**.  
  - For example, you can feed `AppAttachApps_Complete.csv` into [a loop that publishes multiple apps, assigns them to host pools, and assigns user groups — all at once.](https://github.com/Handover2AI/avd-appattach/tree/main/CreateMultipleApps)

- **Round‑trip workflow**  
  - Export existing apps → edit or extend the CSV → re‑import to create/update multiple apps consistently.

---

## 📌 Note on `hostpool_packagepull` and `resourcegroup_hostpool_packagepull`:  
  These two columns are intentionally left **empty** in both Step 1 and Step 2 export scripts because the App Attach package object does not store the original host pool and resource group used during package import.
  
  When you later use the exported CSV as input for [**`Create-MultipleAppAttach.ps1`**](https://github.com/Handover2AI/avd-appattach/tree/main/CreateMultipleApps), you can manually fill in these columns with the correct values for each app. This ensures the script knows which host pool to pull package information from (`hostpool_packagepull`) and which resource group that host pool resides in (`resourcegroup_hostpool_packagepull`).

---

## 📂 Suggested Script Names

- **Step 1:** `Get-AllAppAttachStep1.ps1`  
- **Step 2:** `Get-AllAppAttachStep2.ps1`  

This naming convention makes it clear which script is for the fast export and which is for enrichment.

---

## 🔄 Lifecycle Diagram

```text
+------------------+       +------------------+       +------------------+
|   Export Step 1  | --->  |   Export Step 2  | --->  |   Bulk Creation  |
|  Fast CSV (IDs)  |       | Enriched CSV     |       |  Import & Assign |
+------------------+       +------------------+       +------------------+



