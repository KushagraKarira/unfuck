# --- [Self-Elevate] ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- [Font Logic] ---
$GlobalFont = "Inter"
$CheckFont = New-Object System.Drawing.Font($GlobalFont, 10)
if ($CheckFont.Name -ne $GlobalFont) { $GlobalFont = "Segoe UI" }

# --- [Visual Identity] ---
$Theme = @{
    Bg         = [System.Drawing.Color]::FromArgb(15, 15, 15)
    Card       = [System.Drawing.Color]::FromArgb(25, 25, 25)
    Sidebar    = [System.Drawing.Color]::FromArgb(20, 20, 20)
    Accent     = [System.Drawing.Color]::FromArgb(255, 60, 60)
    Success    = [System.Drawing.Color]::FromArgb(40, 200, 100)
    Warning    = [System.Drawing.Color]::FromArgb(255, 160, 0)
    TextMain   = [System.Drawing.Color]::White
    TextMuted  = [System.Drawing.Color]::FromArgb(160, 160, 160)
    Terminal   = [System.Drawing.Color]::FromArgb(5, 5, 5)
}

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "UNFUCK | High-Performance Restoration"
$Form.Size = New-Object System.Drawing.Size(1200, 950)
$Form.BackColor = $Theme.Bg
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedSingle"

# --- [Header: System Info] ---
$Header = New-Object System.Windows.Forms.Panel -Property @{Dock="Top"; Height=80; BackColor=$Theme.Sidebar}
$Form.Controls.Add($Header)

$OS = (Get-CimInstance Win32_OperatingSystem)
$Uptime = (Get-Date) - $OS.LastBootUpTime
$SysInfo = New-Object System.Windows.Forms.Label -Property @{
    Text = "SYSTEM: $($env:COMPUTERNAME) | OS: $($OS.Caption) ($($OS.OSArchitecture)) | UPTIME: $($Uptime.Days)d $($Uptime.Hours)h"
    Location = New-Object System.Drawing.Point(25, 25)
    Size = New-Object System.Drawing.Size(1100, 30)
    ForeColor = $Theme.TextMuted
    Font = New-Object System.Drawing.Font($GlobalFont, 10, [System.Drawing.FontStyle]::Bold)
}
$Header.Controls.Add($SysInfo)

# --- [Navigation Sidebar] ---
$Nav = New-Object System.Windows.Forms.TabControl
$Nav.Size = New-Object System.Drawing.Size(1140, 520)
$Nav.Location = New-Object System.Drawing.Point(20, 90)
$Nav.Alignment = "Top"
$Nav.SizeMode = "Fixed"
$Nav.ItemSize = New-Object System.Drawing.Size(568, 45)
$Form.Controls.Add($Nav)

$TabHome  = New-Object System.Windows.Forms.TabPage -Property @{Text="CORE MODIFICATIONS"; BackColor=$Theme.Bg}
$TabApps  = New-Object System.Windows.Forms.TabPage -Property @{Text="SOFTWARE DEPLOYMENT"; BackColor=$Theme.Bg}
$Nav.TabPages.AddRange(@($TabHome, $TabApps))

# --- [Logging Engine] ---
$LogPanel = New-Object System.Windows.Forms.Panel -Property @{Location=New-Object System.Drawing.Point(20, 620); Size=New-Object System.Drawing.Size(1145, 270); BackColor=$Theme.Terminal}
$Form.Controls.Add($LogPanel)

$LogBox = New-Object System.Windows.Forms.RichTextBox -Property @{
    Dock = "Fill"
    BackColor = $Theme.Terminal
    ForeColor = $Theme.TextMain
    BorderStyle = "None"
    ReadOnly = $true
    Font = New-Object System.Drawing.Font("Consolas", 10)
}
$LogPanel.Controls.Add($LogBox)

# Clear Logs Button
$BtnClearLog = New-Object System.Windows.Forms.Button -Property @{
    Text = "CLEAR LOGS"
    Size = New-Object System.Drawing.Size(100, 25)
    Location = New-Object System.Drawing.Point(1030, 10)
    FlatStyle = "Flat"
    BackColor = $Theme.Sidebar
    ForeColor = $Theme.TextMuted
    Font = New-Object System.Drawing.Font($GlobalFont, 7)
}
$BtnClearLog.FlatAppearance.BorderSize = 0
$BtnClearLog.Add_Click({ $LogBox.Clear() })
$LogPanel.Controls.Add($BtnClearLog)
$BtnClearLog.BringToFront()

function Write-Log ($Msg, $Type = "Info") {
    $LogBox.Invoke([Action[string, string]]{
        param($m, $t)
        $LogBox.SelectionStart = $LogBox.TextLength
        $LogBox.SelectionColor = switch ($t) {
            "Success" { $Theme.Success }
            "Warning" { $Theme.Warning }
            "Error"   { $Theme.Accent }
            Default   { $Theme.TextMuted }
        }
        $LogBox.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] > $m`n")
        $LogBox.ScrollToCaret()
    }, $Msg, $Type)
}

# --- [Component Factories] ---
function New-Section ($Title, $X, $Y, $Parent) {
    $L = New-Object System.Windows.Forms.Label -Property @{
        Text = $Title.ToUpper()
        Location = New-Object System.Drawing.Point($X, $Y)
        Size = New-Object System.Drawing.Size(350, 25)
        ForeColor = $Theme.Accent
        Font = New-Object System.Drawing.Font($GlobalFont, 9, [System.Drawing.FontStyle]::Bold)
    }
    $Parent.Controls.Add($L)
}

function New-Tweak ($Title, $Desc, $X, $Y, $Action, $Parent) {
    $P = New-Object System.Windows.Forms.Panel
    $P.Location = New-Object System.Drawing.Point($X, $Y)
    $P.Size = New-Object System.Drawing.Size(350, 100)
    $P.BackColor = $Theme.Card
    
    $B = New-Object System.Windows.Forms.Button
    $B.Text = $Title
    $B.Dock = "Top"
    $B.Height = 55
    $B.FlatStyle = "Flat"
    $B.FlatAppearance.BorderSize = 0
    $B.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35)
    $B.ForeColor = $Theme.TextMain
    $B.Font = New-Object System.Drawing.Font($GlobalFont, 10, [System.Drawing.FontStyle]::Bold)
    
    $B.Add_MouseEnter({ $this.BackColor = $Theme.Accent })
    $B.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35) })
    $B.Add_Click($Action)

    $L = New-Object System.Windows.Forms.Label
    $L.Text = $Desc
    $L.Dock = "Bottom"
    $L.Height = 40
    $L.TextAlign = "MiddleCenter"
    $L.ForeColor = $Theme.TextMuted
    $L.Font = New-Object System.Drawing.Font($GlobalFont, 8)

    $P.Controls.Add($B)
    $P.Controls.Add($L)
    $Parent.Controls.Add($P)
}

# --- [TAB 1: CORE TWEAKS] ---
New-Section "Maintenance & Updates" 20 20 $TabHome
New-Tweak "Deep Repair" "DISM / SFC Component Fix" 20 50 { 
    Write-Log "Starting repair sequence..." "Warning"
    sfc /scannow; dism /online /cleanup-image /restorehealth
    Write-Log "Integrity check finished." "Success"
} $TabHome

New-Tweak "Software Update" "Batch WinGet Upgrade" 20 160 { 
    Write-Log "Syncing Winget repos..." "Warning"
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
    Write-Log "Software library updated." "Success"
} $TabHome

New-Tweak "OS Patching" "Force Windows Updates" 20 270 { 
    Write-Log "Triggering Windows Update..." "Warning"
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false | Out-Null
    if (-not (Get-Module -ListAvailable PSWindowsUpdate)) { Install-Module PSWindowsUpdate -Force -SkipPublisherCheck }
    Get-WindowsUpdate -Install -AcceptAll -AutoReboot:$false
    Write-Log "OS Patching cycle complete." "Success"
} $TabHome

New-Section "Optimization & UI" 390 20 $TabHome
New-Tweak "Classic Menu" "Win10 Right-Click for Win11" 390 50 { 
    reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve | Out-Null
    Write-Log "Classic Context Menu Enabled. Restart Explorer to apply." "Success"
} $TabHome

New-Tweak "Privacy Purge" "Kill Telemetry & Tracking" 390 160 { 
    Write-Log "Nuking Telemetry..." "Warning"
    Get-Service -Name "DiagTrack", "dmwappushservice" | Stop-Service -PassThru | Set-Service -StartupType Disabled
    Write-Log "Telemetry services disabled." "Success"
} $TabHome

New-Tweak "Gaming Mode" "Zero-Throttle & HAGS" 390 270 { 
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value 0
    Write-Log "Ultimate Power & Latency Tweaked." "Success"
} $TabHome

New-Section "Advanced Cleanup" 760 20 $TabHome
New-Tweak "Debloat Start" "Remove OEM Junk Apps" 760 50 { 
    $Apps = @("*TikTok*", "*Instagram*", "*Facebook*", "*Disney*", "*PrimeVideo*")
    foreach ($a in $Apps) { Get-AppxPackage $a | Remove-AppxPackage -ErrorAction SilentlyContinue }
    Write-Log "Start Menu Debloated." "Success"
} $TabHome

New-Tweak "Recall Nuclear" "Total AI Feature Removal" 760 160 { 
    Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -Remove -NoRestart
    Write-Log "AI Recall feature purged." "Success"
} $TabHome

# --- [TAB 2: APP DEPLOYMENT] ---
$SearchContainer = New-Object System.Windows.Forms.Panel -Property @{Location=New-Object System.Drawing.Point(25, 25); Size=New-Object System.Drawing.Size(1080, 430); BackColor=$Theme.Card}
$TabApps.Controls.Add($SearchContainer)

$SearchInput = New-Object System.Windows.Forms.TextBox -Property @{
    Location=New-Object System.Drawing.Point(15, 15); Size=New-Object System.Drawing.Size(850, 40); BackColor=$Theme.Bg; ForeColor=$Theme.TextMain; BorderStyle="FixedSingle"; Font=New-Object System.Drawing.Font($GlobalFont, 12)
}
$SearchContainer.Controls.Add($SearchInput)

$BtnSearch = New-Object System.Windows.Forms.Button -Property @{
    Text="QUERY REPO"; Location=New-Object System.Drawing.Point(880, 15); Size=New-Object System.Drawing.Size(180, 32); FlatStyle="Flat"; BackColor=$Theme.Accent; ForeColor=$Theme.TextMain; Font=New-Object System.Drawing.Font($GlobalFont, 9, [System.Drawing.FontStyle]::Bold)
}
$SearchContainer.Controls.Add($BtnSearch)

$AppGrid = New-Object System.Windows.Forms.ListView -Property @{
    Location=New-Object System.Drawing.Point(15, 65); Size=New-Object System.Drawing.Size(1045, 340); BackColor=$Theme.Bg; ForeColor=$Theme.TextMain; BorderStyle="None"; View="Details"; FullRowSelect=$true; CheckBoxes=$true; Font=New-Object System.Drawing.Font($GlobalFont, 10)
}
$AppGrid.Columns.Add("Application", 450) | Out-Null
$AppGrid.Columns.Add("Package ID", 400) | Out-Null
$AppGrid.Columns.Add("Source", 150) | Out-Null
$SearchContainer.Controls.Add($AppGrid)

$BtnDeploy = New-Object System.Windows.Forms.Button -Property @{
    Text="PROVISION SELECTED PACKAGES"; Location=New-Object System.Drawing.Point(25, 470); Size=New-Object System.Drawing.Size(1080, 40); FlatStyle="Flat"; BackColor=$Theme.Success; ForeColor=$Theme.TextMain; Font=New-Object System.Drawing.Font($GlobalFont, 10, [System.Drawing.FontStyle]::Bold)
}
$TabApps.Controls.Add($BtnDeploy)

# --- [LOGIC] ---
$BtnSearch.Add_Click({
    if ([string]::IsNullOrWhiteSpace($SearchInput.Text)) { return }
    $AppGrid.Items.Clear()
    Write-Log "Searching for '$($SearchInput.Text)'..." "Warning"
    $Raw = winget search $SearchInput.Text --source winget | Select-Object -Skip 2
    foreach ($L in $Raw) {
        if ($L -match "^\s*(?<N>.+?)\s+(?<I>\S+)\s+(?<V>\S+)\s+(?<S>\S+)") {
            $Item = New-Object System.Windows.Forms.ListViewItem($Matches['N'])
            $Item.SubItems.Add($Matches['I']); $Item.SubItems.Add($Matches['S'])
            $AppGrid.Items.Add($Item)
        }
    }
})

$BtnDeploy.Add_Click({
    $Checked = $AppGrid.CheckedItems
    if ($Checked.Count -eq 0) { Write-Log "No packages selected." "Warning"; return }
    foreach ($Item in $Checked) {
        $ID = $Item.SubItems[1].Text
        Write-Log "Installing $ID..." "Warning"
        Start-Process winget -ArgumentList "install --id $ID --silent --accept-package-agreements" -NoNewWindow -Wait
        Write-Log "Done: $ID" "Success"
    }
})

$SearchInput.Add_KeyDown({ if ($_.KeyCode -eq "Enter") { $BtnSearch.PerformClick() }})

[void]$Form.ShowDialog()
