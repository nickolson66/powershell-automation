# PowerShell Automation Scripts

Collection of real-world PowerShell scripts developed in MSP and enterprise environments to automate system administration, networking, and software management tasks.

## Scripts

### 🔹 Wi-Fi SSID Restriction (`restrict-wifi-ssid.ps1`)
Restricts a Windows device to a single approved Wi-Fi network by creating a WLAN profile and applying network filters.

**Key Features:**
- Enforces connection to a specific SSID
- Blocks all other wireless networks
- Uses native Windows tools (`netsh`)
- Includes logging for troubleshooting
- Automatically connects to the approved network

---

### 🔹 Smart View Deployment Prep (`smartview-install-prep.ps1`)
Automates preparation for Oracle Smart View deployment by detecting installed versions, removing outdated versions, and cleaning up system artifacts.

**Key Features:**
- Detects installed Smart View versions via registry
- Prevents unnecessary reinstall of current version
- Removes legacy versions (MSI + EXE handling)
- Cleans leftover files and directories
- Integrates with NinjaOne deployment workflows via exit codes

---

## Skills Demonstrated
- PowerShell scripting and automation
- Windows system administration
- Software deployment and remediation
- Networking configuration and controls
- Log analysis and troubleshooting
- Process automation in managed environments

---

## Use Cases
These scripts are designed for:
- Managed Service Providers (MSPs)
- Enterprise IT environments
- Automated deployments and system remediation
- Standardizing configurations across multiple endpoints

---

## Requirements
- Windows environment
- Administrator privileges
- PowerShell 5.1+

---

## Notes
These scripts were developed and tested in real-world environments and are intended for administrative and automation purposes.
