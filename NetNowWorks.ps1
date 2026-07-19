# ----------------------------------------------------
# AUTO-ELEVATE TO ADMINISTRATOR
# ----------------------------------------------------
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($PSCommandPath) {
        Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit
    } else {
        Write-Warning "Running unsaved code: Cannot automatically prompt for UAC elevation."
        Write-Host "Please open PowerShell as Administrator manually and paste this script." -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to exit..."
        exit
    }
}

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " Maximizing Network Adapter Stability for MS Access" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# ----------------------------------------------------
# 1. DEFINE STATIC TEXT PROPERTY TARGETS
# ----------------------------------------------------
$StaticRules = @{
    # Power Management (Keep the hardware 100% awake)
    "*Energy*Efficient*"        = "Disabled"
    "*Green*Ethernet*"          = "Disabled"
    "*Advanced EEE*"            = "Disabled"
    "*Idle Power Saving*"       = "Disabled"
    "*Power Saving*"            = "Disabled"
    "*Adaptive Link Speed*"     = "Disabled"
    "*idle power down*"         = "No Restriction"
    "*Battery Mode*"            = "Not Speed Down"
    "*WOL & Shutdown*"          = "Not Speed Down"
    "*Wake on link change*"     = "Disabled"
    "*Wake on Magic*"           = "Disabled"
    "*Wake on pattern*"         = "Disabled"
    
    # Packet Processing Offloads (Force Windows Stack stability over buggy firmware)
    "*Large Send Offload*"      = "Disabled"
    "*Recv Segment Coalescing*" = "Disabled"
    "*ARP Offload*"             = "Disabled"
    "*NS Offload*"              = "Disabled"
    "*Checksum Offload*"        = "Disabled"
    
    # Latency Tuning
    "*Flow Control*"            = "Disabled"
    "*Interrupt Moderation*"    = "Disabled"
    "*Jumbo*"                   = "Disabled"
}

# ----------------------------------------------------
# 2. DISCOVER AND PROCESS ALL PHYSICAL ADAPTERS
# ----------------------------------------------------
$adapters = Get-NetAdapter -Physical

if (-not $adapters) {
    Write-Warning "No physical network adapters found!"
} else {
    foreach ($adapter in $adapters) {
        Write-Host "`n[+] Optimizing: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Yellow
        
        # Pull current properties dynamically
        $advancedProps = Get-NetAdapterAdvancedProperty -Name $adapter.Name

        foreach ($prop in $advancedProps) {
            
            # --- Handle Static Text Optimizations ---
            foreach ($rule in $StaticRules.GetEnumerator()) {
                if ($prop.DisplayName -like $rule.Key) {
                    if ($prop.DisplayValue -eq $rule.Value) { continue } # Already optimized
                    
                    try {
                        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName $prop.DisplayName -DisplayValue $rule.Value -ErrorAction Stop
                        Write-Host "  -> Set: $($prop.DisplayName) = $($rule.Value)" -ForegroundColor Green
                    } catch {
                        Write-Host "  -> Skipped: $($prop.DisplayName) (Value unsupported)" -ForegroundColor DarkGray
                    }
                }
            }

            # --- Smart Dynamic Buffer Maximization ---
            # Your current buffers are at 37/40. We step downward from 512 to find the max allowed.
            if ($prop.DisplayName -like "*Receive Buffers*" -or $prop.DisplayName -like "*Transmit Buffers*") {
                $bufferSteps = @("512", "256", "128", "64")
                foreach ($val in $bufferSteps) {
                    if ([int]$prop.DisplayValue -ge [int]$val) { break } # Already high or optimal
                    try {
                        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName $prop.DisplayName -DisplayValue $val -ErrorAction Stop
                        Write-Host "  -> Maximized: $($prop.DisplayName) = $val" -ForegroundColor Green
                        break
                    } catch { continue }
                }
            }

            # --- Smart USB Request Block (URB) Maximization ---
            # USB specific allocation pools. Default is 6/9. We attempt to scale safely.
            if ($prop.DisplayName -like "*Receive URBs*" -or $prop.DisplayName -like "*Transmit URBs*") {
                $urbSteps = @("64", "32", "16")
                foreach ($val in $urbSteps) {
                    if ([int]$prop.DisplayValue -ge [int]$val) { break }
                    try {
                        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName $prop.DisplayName -DisplayValue $val -ErrorAction Stop
                        Write-Host "  -> Maximized: $($prop.DisplayName) = $val" -ForegroundColor Green
                        break
                    } catch { continue }
                }
            }
        }
    }
}

# ----------------------------------------------------
# 3. APPLY SYSTEM-WIDE SMB LEASING BUG FIX
# ----------------------------------------------------
Write-Host "`n[+] Verifying SMB DisableLeasing Registry Workaround..." -ForegroundColor Yellow

$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters"
if (Test-Path $RegPath) {
    $currentVal = (Get-ItemProperty -Path $RegPath -Name "DisableLeasing" -ErrorAction SilentlyContinue).DisableLeasing
    if ($currentVal -ne 1) {
        New-ItemProperty -Path $RegPath -Name "DisableLeasing" -Value 1 -PropertyType DWORD -Force | Out-Null
        Write-Host "  -> DisableLeasing configured to 1. Restarting LanmanServer..." -ForegroundColor Green
        Restart-Service -Name "LanmanServer" -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "  -> DisableLeasing is already safely configured." -ForegroundColor Green
    }
}

# ----------------------------------------------------
# 4. DISABLE OS USB SELECTIVE SUSPEND
# ----------------------------------------------------
Write-Host "`n[+] Disabling Host USB Selective Suspend Power Management..." -ForegroundColor Yellow

powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a84c312-a001-40c3-b31f-1393d254d070 48e6b7a6-50f2-4389-a784-1779c7b048db 0
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a84c312-a001-40c3-b31f-1393d254d070 48e6b7a6-50f2-4389-a784-1779c7b048db 0
powercfg /setactive SCHEME_CURRENT

Write-Host "  -> Windows OS Power management policies updated." -ForegroundColor Green

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host " Optimization Complete! Please restart your PC." -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# ----------------------------------------------------
# ENFORCED PAUSE FOR LOG REVIEW
# ----------------------------------------------------
Write-Host ""
Read-Host "Press Enter to close this window..."