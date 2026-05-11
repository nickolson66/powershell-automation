# =============================================================
# Tessitura Folder Update Script
# =============================================================

# ROADMAP:
# Step 1 - Test connection to network share
#           If unreachable, stop the script
#
# Step 2 - Rename existing v16 and v16013 folders to _old
#           If folders not found, skip and continue
#
# Step 3 - Copy new v16 and v16013 folders from network share
#           If source folders not found, skip and log
# =============================================================

# NOTE: Run cleanup script separately after confirming app works
# =============================================================

# --- STEP 1: Test Network Share Connection ---

$sourcePath = "\\fileserver\Tessitura"

Write-Host "Step 1: Testing connection to network share..."

if (-not (Test-Path $sourcePath)) {

    Write-Host "Cannot reach network share: $sourcePath - Stopping script."
    exit 1

}

Write-Host "Network share accessible, proceeding..."

# --- STEP 2: Rename Existing Folders to _old ---

Write-Host "Step 2: Renaming existing folders to _old..."

$folders = @(

    "C:\Tessitura\v16",
    "C:\Tessitura\v16013"

)

foreach ($folder in $folders) {

    if (Test-Path $folder) {

        $newName = "$folder`_old"

        Rename-Item -Path $folder -NewName $newName -Force

        Write-Host "Renamed: $folder -> $newName"

    } else {

        Write-Host "Not found, skipping: $folder"

    }

}

# --- STEP 3: Copy New Folders from Network Share ---

Write-Host "Step 3: Copying new folders from network share..."

$transfers = @(

    @{ Source = "$sourcePath\v16";    Destination = "C:\Tessitura\v16" },
    @{ Source = "$sourcePath\v16013"; Destination = "C:\Tessitura\v16013" }

)

foreach ($transfer in $transfers) {

    if (Test-Path $transfer.Source) {

        Copy-Item -Path $transfer.Source `
                  -Destination $transfer.Destination `
                  -Recurse `
                  -Force

        Write-Host "Copied: $($transfer.Source) -> $($transfer.Destination)"

    } else {

        Write-Host "Source not found, skipping: $($transfer.Source)"

    }

}

Write-Host "Script complete. Please verify the app is working before running the cleanup script."
