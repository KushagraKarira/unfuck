# 1. Request Admin Privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Requesting Administrator privileges..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Starting System Maintenance..." -ForegroundColor Green

# 2. DISM (Repair Windows Image)
Write-Host "`n[1/5] Running DISM to check and repair the Windows image..." -ForegroundColor Cyan
DISM /Online /Cleanup-Image /RestoreHealth

# 3. SFC (Repair System Files)
Write-Host "`n[2/5] Running SFC to scan and repair system files..." -ForegroundColor Cyan
sfc /scannow

# 4. Windows Update 
# Note: This uses the official PSWindowsUpdate module to properly install updates via command line.
Write-Host "`n[3/5] Installing Windows Updates..." -ForegroundColor Cyan
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue | Out-Null
Install-Module PSWindowsUpdate -Force -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot

# 5. Winget (Update Apps)
Write-Host "`n[4/5] Updating applications via Winget..." -ForegroundColor Cyan
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements

# 6. Defrag (Optimize Drive C)
Write-Host "`n[5/5] Optimizing and defragmenting the C: drive..." -ForegroundColor Cyan
Optimize-Volume -DriveLetter C -ReTrim -Defrag -Verbose

Write-Host "`nMaintenance Complete! Please restart your computer if any updates require it." -ForegroundColor Green
Pause