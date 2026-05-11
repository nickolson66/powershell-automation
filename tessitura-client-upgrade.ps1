# =============================================================
# Tessitura Folder Update Script
# =============================================================
# ROADMAP:
# Pre-Check - Check if script has already run successfully
#              If flag file exists, stop the script
# Step 1    - Test connection to network share
#              If unreachable, stop the script
# Step 2    - Rename existing v16 and v16013 folders to _old
#              If folders not found, skip and continue
# Step 3    - Create empty v16 and v16013 folders
# Step 4    - Copy new v16 and v16013 folders from network share
#              into the newly created folders
#              If source folders not found, skip and log
# Step 5    - Create flag file to prevent script running again
# =============================================================
# NOTE: Run cleanup script separately after confirming app works
# =============================================================

# --- PRE-CHECK: Has this script already run successfully? ---
$flagFile = "C:\Tessitura\update_complete.flag"

Write-Host "Pre-Check: Checking if script has already run successfully..."

if (Test-Path $flagFile) {
    Write-Host "Update already completed successfully on this machine. Exiting."
    exit 0
}

Write-Host "No flag file found, proceeding with update..."

# --- STEP 1: Test Network Share Connection ---
$sourcePath = "\\tessdocs.rpac.org\Tessitura"

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

# --- STEP 3: Create Empty Destination Folders ---
Write-Host "Step 3: Creating empty destination folders..."

$destinations = @(
    "C:\Tessitura\v16",
    "C:\Tessitura\v16013"
)

foreach ($destination in $destinations) {
    New-Item -Path $destination -ItemType Directory -Force
    Write-Host "Created: $destination"
}

# --- STEP 4: Copy New Folders from Network Share ---
Write-Host "Step 4: Copying new folders from network share..."

$transfers = @(
    @{ Source = "$sourcePath\v16";    Destination = "C:\Tessitura\v16" },
    @{ Source = "$sourcePath\v16013"; Destination = "C:\Tessitura\v16013" }
)

foreach ($transfer in $transfers) {
    if (Test-Path $transfer.Source) {
        Copy-Item -Path $transfer.Source\* -Destination $transfer.Destination -Recurse -Force
        Write-Host "Copied: $($transfer.Source) -> $($transfer.Destination)"
    } else {
        Write-Host "Source not found, skipping: $($transfer.Source)"
    }
}

# --- STEP 5: Create Flag File ---
Write-Host "Step 5: Creating flag file..."

New-Item -Path $flagFile -ItemType File -Force
Write-Host "Flag file created at $flagFile. Script will not run again on this machine."

Write-Host "Script complete. Please verify the app is working before running the cleanup script."
