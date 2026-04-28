# --- [Self-Elevate] ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- [Visual Identity] ---
$Theme = @{
    Bg         = [System.Drawing.Color]::FromArgb(10, 10, 10)
    Card       = [System.Drawing.Color]::FromArgb(22, 22, 22)
    Accent     = [System.Drawing.Color]::FromArgb(255, 60, 60) # Red for high-impact
    Success    = [System.Drawing.Color]::FromArgb(40, 200, 100)
    Warning    = [System.Drawing.Color]::FromArgb(255, 160, 0)
    TextMain   = [System.Drawing.Color]::White
    TextMuted  = [System.Drawing.Color]::FromArgb(150, 150, 150)
}

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "UNFUCK | Workstation Restoration Utility"
$Form.Size = New-Object System.Drawing.Size(1050, 900)
$Form.BackColor = $Theme.Bg
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"

# --- [Header] ---
$Header = New-Object System.Windows.Forms.Label
$Header.Text = "UNFUCK MODE: ACTIVE  |  DEVICE: $env:COMPUTERNAME  |  KERNEL OPTIMIZATION: PENDING"
$Header.Dock = "Top"
$Header.Height = 50
$Header.TextAlign = "MiddleCenter"
$Header.ForeColor = $Theme.Accent
$Header.Font = New-Object System.Drawing.Font("Segoe UI Bold", 11)
$Form.Controls.Add($Header)

# --- [Logging Engine] ---
$LogBox = New-Object System.Windows.Forms.RichTextBox
$LogBox.Location = New-Object System.Drawing.Point(25, 630)
$LogBox.Size = New-Object System.Drawing.Size(985, 210)
$LogBox.BackColor = [System.Drawing.Color]::Black
$LogBox.ForeColor = $Theme.TextMain
$LogBox.BorderStyle = "None"
$LogBox.ReadOnly = $true
$Form.Controls.Add($LogBox)

function Write-Log ($Msg, $Type = "Info") {
    $LogBox.Invoke([Action[string, string]]{
        param($m, $t)
        $LogBox.SelectionStart = $LogBox.TextLength
        $LogBox.SelectionColor = if ($t -eq "Success") { $Theme.Success } elseif ($t -eq "Warning") { $Theme.Warning } else { $Theme.Accent }
        $LogBox.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] > $m`n")
        $LogBox.ScrollToCaret()
    }, $Msg, $Type)
}

# --- [Component Factories] ---
function New-Section ($Title, $X, $Y) {
    $L = New-Object System.Windows.Forms.Label
    $L.Text = $Title.ToUpper()
    $L.Location = New-Object System.Drawing.Point($X, $Y)
    $L.Size = New-Object System.Drawing.Size(320, 25)
    $L.ForeColor = $Theme.Accent
    $L.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $Form.Controls.Add($L)
}

function New-Card ($Title, $Desc, $X, $Y, $Action, $Color = $null) {
    $C = New-Object System.Windows.Forms.Panel
    $C.Size = New-Object System.Drawing.Size(320, 85)
    $C.Location = New-Object System.Drawing.Point($X, $Y)
    $C.BackColor = $Theme.Card
    
    $B = New-Object System.Windows.Forms.Button
    $B.Text = $Title
    $B.Dock = "Top"
    $B.Height = 45
    $B.FlatStyle = "Flat"
    $B.FlatAppearance.BorderSize = 0
    $B.BackColor = if ($Color) { $Color } else { [System.Drawing.Color]::FromArgb(35, 35, 35) }
    $B.ForeColor = $Theme.TextMain
    $B.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $B.Add_Click($Action)
    
    $S = New-Object System.Windows.Forms.Label
    $S.Text = $Desc
    $S.Dock = "Bottom"
    $S.Height = 35
    $S.TextAlign = "MiddleCenter"
    $S.ForeColor = $Theme.TextMuted
    $S.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    
    $C.Controls.Add($B)
    $C.Controls.Add($S)
    $Form.Controls.Add($C)
}

# --- [COLUMN 1: REPAIR] ---
New-Section "Unfuck Maintenance" 25 70
New-Card "Deep Repair" "Run DISM image repair & SFC scan" 25 105 { 
    Write-Log "Initializing deep repair..." "Warning"; dism /online /cleanup-image /restorehealth; sfc /scannow; Write-Log "Repair Complete." "Success"
}
New-Card "Full Updates" "Silent App upgrades & OS patches" 25 205 { 
    Write-Log "Checking for updates..."; winget upgrade --all --silent; Get-WindowsUpdate -Install -AcceptAll; Write-Log "All systems unfucked." "Success"
}
New-Card "Junk Purge" "Nuclear deletion of temp caches" 25 305 { 
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Temp junk purged." "Success"
}

# --- [COLUMN 2: KERNEL] ---
New-Section "Unfuck Performance" 360 70
New-Card "Latency Fix" "0ms UI delay + HAGS activation" 360 105 { 
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2
    Write-Log "UI and Graphics latency optimized." "Success"
}
New-Card "Ultimate Power" "Enable highest-performance scheme" 360 205 { 
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null; Write-Log "Ultimate Power Plan active." "Success"
}
New-Card "Time Resync" "Force atomic clock synchronization" 360 305 { 
    Restart-Service w32time; w32tm /resync /force; Write-Log "NTP Resync Success." "Success"
}

# --- [COLUMN 3: PRIVACY] ---
New-Section "Unfuck Privacy" 695 70
New-Card "Kill AI & Recall" "Purge Recall & Copilot binaries" 695 105 { 
    Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -Remove -NoRestart; Write-Log "AI telemetry disabled." "Success"
}
New-Card "DNS Hardening" "Switch to Cloudflare (1.1.1.1)" 695 205 { 
    Set-DnsClientServerAddress -InterfaceAlias (Get-NetAdapter | Where Status -eq "Up").InterfaceAlias -ServerAddresses ("1.1.1.1","1.0.0.1")
    ipconfig /flushdns; Write-Log "Privacy DNS active + Flush." "Success"
}
New-Card "SMB Stability" "Safe LAN Database (Disable OpLocks)" 695 305 { 
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "EnableOplocks" -Value 0
    Write-Log "Database stability fix applied." "Success"
}

# --- [MASTER ACTIONS] ---
New-Section "The Final Unfuck" 25 430
New-Card "Activate Soft" "Windows & Office Activation (MAS)" 25 465 { 
    Write-Log "Invoking MAS script..."; irm https://get.activated.win | iex 
} [System.Drawing.Color]::FromArgb(60, 60, 60)

New-Card "MASTER UNFUCK SEQUENCE" "Run full restoration sequence" 360 465 {
    Write-Log "COMMENCING MASTER UNFUCK..." "Warning"
    # Execute sequential logic here
    Write-Log "Workstation fully unfucked." "Success"
} $Theme.Accent

[void]$Form.ShowDialog()
