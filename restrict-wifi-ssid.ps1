#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Configuration ────────────────────────────────────────────
$AllowedSSID  = "YOUR_SSID_HERE"
$ProfileName  = "Restricted-WiFi"
$ProfileFile  = "$env:TEMP\wifi_profile.xml"
$LogFile      = "$env:TEMP\wifi_restriction_log.txt"
# ─────────────────────────────────────────────────────────────

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$ts] $msg"
    Write-Host $msg
}

try {
    Log "Starting Wi-Fi restriction for SSID: $AllowedSSID"

    # 1. Verify WLAN service is running
    $svc = Get-Service -Name "WlanSvc" -ErrorAction SilentlyContinue
    if (-not $svc -or $svc.Status -ne "Running") {
        throw "WLAN AutoConfig service is not running. Enable it first."
    }

    # 2. Write the allowed WLAN profile XML
    $profileXml = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$ProfileName</name>
    <SSIDConfig>
        <SSID>
            <name>$AllowedSSID</name>
        </SSID>
        <nonBroadcast>false</nonBroadcast>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
                <authEncryption>
                    <authentication>WPA2PSK</authentication>
                    <encryption>AES</encryption>
                    <useOneX>false</useOneX>
                </authEncryption>
            <keyMaterial></keyMaterial>
            </security>
    </MSM>
</WLANProfile>
"@
    Set-Content -Path $ProfileFile -Value $profileXml -Encoding UTF8
    Log "Profile XML written to $ProfileFile"

    # 3. Add the Wi-Fi profile to Windows
    $addResult = netsh wlan add profile filename="$ProfileFile" user=all
    Log "Add profile: $addResult"

    # 4. Set filter: deny everything, then allow only our SSID
    netsh wlan set profileparameter name="$ProfileName" autoSwitch=yes | Out-Null
    netsh wlan set filtermode allow | Out-Null          # Enable filter mode
    netsh wlan add filter permission=denyall networktype=infrastructure | Out-Null
    netsh wlan add filter permission=allow ssid="$AllowedSSID" networktype=infrastructure | Out-Null
    Log "Filters applied: deny-all + allow '$AllowedSSID'"

    # 5. Remove temp file
    Remove-Item $ProfileFile -Force -ErrorAction SilentlyContinue

    # 6. Connect to the allowed network
    $connect = netsh wlan connect name="$ProfileName" ssid="$AllowedSSID"
    Log "Connect attempt: $connect"

    Write-Host ""
    Write-Host "Done. This device will only see/join: $AllowedSSID" -ForegroundColor Green
    Write-Host "Log saved to: $LogFile"

} catch {
    Log "ERROR: $_"
    Write-Error $_
    exit 1
}
