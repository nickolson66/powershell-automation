# ============================================================
# Oracle Smart View - Install Prep Script
# Managed Deployment via NinjaOne
# ============================================================
# TASKS:
#   1. Check if Smart View 25.200 is already installed
#   2. Kill Office processes
#   3. Uninstall all other Smart View versions
#   4. Cleanup leftover files
# ============================================================
# EXIT CODES:
#   0 = Prep complete, NinjaOne should proceed with .exe deployment
#   1 = Smart View 25.200 already installed, NinjaOne should SKIP .exe deployment
# ============================================================
# NINJAONE AUTOMATION SETUP:
#   On the step that runs this script, set the condition:
#   "Only run next step if exit code = 0"
#   This ensures the .exe is only pushed when actually needed.
# ============================================================


# ── TASK 1: Check if Smart View 25.200 is already installed ──
function Test-SmartViewInstalled {
    Write-Output "=== TASK 1: Checking for Smart View 25.200 ==="

    $uninstallKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $installed = Get-ItemProperty $uninstallKeys -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -match 'Oracle Smart View|Smart View|SmartView' -and
        $_.DisplayVersion -eq '25.200'
    }

    if ($installed) {
        Write-Output "Smart View 25.200 is already installed. Nothing to do. Exiting."
        exit 1   # NinjaOne reads this and skips the .exe deployment step
    }

    Write-Output "Smart View 25.200 not found. Proceeding with install prep."
}


# ── TASK 2: Kill Office Processes ────────────────────────────
function Stop-OfficeProcesses {
    Write-Output ""
    Write-Output "=== TASK 2: Killing Office processes ==="

    $officeProcs = @('WINWORD', 'EXCEL', 'OUTLOOK', 'POWERPNT', 'MSACCESS', 'olk')

    foreach ($proc in $officeProcs) {
        $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
        if ($running) {
            Write-Output "Stopping: $proc"
            $running | Stop-Process -Force
        }
    }

    Start-Sleep -Seconds 3
    Write-Output "Office processes stopped."
}


# ── TASK 3: Uninstall Old Smart View Versions ────────────────
function Remove-OldSmartView {
    Write-Output ""
    Write-Output "=== TASK 3: Uninstalling old Smart View versions ==="

    $uninstallKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $apps = Get-ItemProperty $uninstallKeys -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -match 'Oracle Smart View|Smart View|SmartView'
    }

    if (-not $apps) {
        Write-Output "No existing Smart View installations found."
        return
    }

    foreach ($app in $apps) {
        $version = [string]$app.DisplayVersion

        # Skip target version as a safety net
        if ($version -eq '25.200') {
            Write-Output "Skipping $($app.DisplayName) v$version (target version)"
            continue
        }

        Write-Output "Uninstalling: $($app.DisplayName) v$version"

        if ($app.UninstallString -match 'MsiExec\.exe') {
            # MSI-based uninstall — extract GUID
            $guid = $null

            if ($app.PSChildName -match '^\{[0-9A-Fa-f-]+\}$') {
                $guid = $app.PSChildName
            }
            elseif ($app.UninstallString -match '\{[0-9A-Fa-f-]+\}') {
                $guid = $matches[0]
            }

            if ($guid) {
                Write-Output "Running MSI uninstall for GUID: $guid"
                Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn REBOOT=ReallySuppress" -Wait -NoNewWindow
            }
            else {
                Write-Output "WARNING: Could not determine MSI GUID for $($app.DisplayName). Skipping."
            }
        }
        else {
            # EXE-based uninstall
            $uninstallCmd = $app.UninstallString.Trim('"')
            Write-Output "Running EXE uninstall: $uninstallCmd"
            Start-Process -FilePath $uninstallCmd -ArgumentList "/S /qn /silent" -Wait -NoNewWindow
        }
    }

    Write-Output "Uninstall pass complete."
}


# ── TASK 4: Cleanup Leftover Files ───────────────────────────
function Remove-SmartViewLeftovers {
    Write-Output ""
    Write-Output "=== TASK 4: Cleaning up leftover Smart View files ==="

    $paths = @(
        "C:\Program Files\Oracle\Smart View",
        "${env:ProgramFiles(x86)}\Oracle\Smart View",
        "$env:APPDATA\Oracle\SmartView"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Output "Removing: $path"
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Output "Cleanup complete."
}


# ============================================================
# MAIN — Run tasks in order
# ============================================================
Test-SmartViewInstalled     # Exit 1 here if 25.200 already present — stops NinjaOne chain
Stop-OfficeProcesses
Remove-OldSmartView
Remove-SmartViewLeftovers

Write-Output ""
Write-Output "=== Smart View install prep complete. Ready for NinjaOne deployment. ==="
exit 0   # NinjaOne reads this and proceeds with .exe deployment
