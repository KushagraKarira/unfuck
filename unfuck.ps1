# --- [Self-Elevate] ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy Bypass", "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- [Visual Identity & Theme] ---
$script:Theme = @{
    Bg          = [System.Drawing.Color]::FromArgb(10, 10, 12)
    Header      = [System.Drawing.Color]::FromArgb(18, 18, 22)
    Card        = [System.Drawing.Color]::FromArgb(28, 28, 34)
    CardHover   = [System.Drawing.Color]::FromArgb(40, 40, 48)
    Accent      = [System.Drawing.Color]::FromArgb(0, 120, 215) 
    AccentGlow  = [System.Drawing.Color]::FromArgb(0, 180, 255)
    Success     = [System.Drawing.Color]::FromArgb(46, 204, 113)
    Warning     = [System.Drawing.Color]::FromArgb(241, 196, 15)
    Danger      = [System.Drawing.Color]::FromArgb(231, 76, 60)
    TextMain    = [System.Drawing.Color]::FromArgb(240, 240, 240)
    TextMuted   = [System.Drawing.Color]::FromArgb(140, 140, 150)
    Border      = [System.Drawing.Color]::FromArgb(45, 45, 55)
}

$GlobalFont = "Segoe UI Variable Display"
$CheckFont = New-Object System.Drawing.Font($GlobalFont, 10)
if ($CheckFont.Name -ne $GlobalFont) { $GlobalFont = "Segoe UI" }

# --- [Form Setup] ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text            = "ADMINWORKS"
$Form.Size            = New-Object System.Drawing.Size(1250, 1050)
$Form.BackColor       = $script:Theme.Bg
$Form.StartPosition   = "CenterScreen"
$Form.FormBorderStyle = "None"
$Form.MinimumSize     = New-Object System.Drawing.Size(1100, 850)

# FIX: Bulletproof DoubleBuffering using explicit BindingFlags enumeration
try {
    $bf = [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
    $prop = $Form.GetType().GetProperty("DoubleBuffered", $bf)
    if ($prop) { $prop.SetValue($Form, $true, $null) }
} catch {}

# --- [Header: Window Controls & Device Info] ---
$Header = New-Object System.Windows.Forms.Panel -Property @{Dock="Top"; Height=85; BackColor=$script:Theme.Header}
$Form.Controls.Add($Header)

$TitleLbl = New-Object System.Windows.Forms.Label -Property @{
    Text      = "⚡ ADMINWORKS"
    Location  = New-Object System.Drawing.Point(25, 15); AutoSize = $true
    ForeColor = $script:Theme.TextMain; Font = New-Object System.Drawing.Font($GlobalFont, 12, [System.Drawing.FontStyle]::Bold)
}
$Header.Controls.Add($TitleLbl)

# FIX: Error-resistant IP Discovery
$LocalIP = "Searching..."
try {
    $ipObj = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -match 'Dhcp|Manual' -and $_.InterfaceAlias -notmatch 'Loopback|Virtual' } | Select-Object -First 1
    if ($ipObj) { $LocalIP = $ipObj.IPAddress } else { $LocalIP = "No LAN" }
} catch { $LocalIP = "Scanning..." }

$OS = (Get-CimInstance Win32_OperatingSystem)
$SysInfoLbl = New-Object System.Windows.Forms.Label -Property @{
    Text      = "$($env:COMPUTERNAME) | IP: $LocalIP | $($OS.Caption)"
    Location  = New-Object System.Drawing.Point(25, 45); Size = New-Object System.Drawing.Size(800, 25)
    ForeColor = $script:Theme.TextMuted; Font = New-Object System.Drawing.Font($GlobalFont, 8, [System.Drawing.FontStyle]::Bold)
}
$Header.Controls.Add($SysInfoLbl)

# Live Uptime Label
$UptimeLbl = New-Object System.Windows.Forms.Label -Property @{
    Location  = New-Object System.Drawing.Point(850, 45); Size = New-Object System.Drawing.Size(200, 25)
    ForeColor = $script:Theme.AccentGlow; Font = New-Object System.Drawing.Font($GlobalFont, 8, [System.Drawing.FontStyle]::Bold)
    TextAlign = "TopRight"; Anchor = [System.Windows.Forms.AnchorStyles]"Top, Right"
}
$Header.Controls.Add($UptimeLbl)

$CtrlBox = New-Object System.Windows.Forms.Panel -Property @{Dock="Right"; Width=150}
$Header.Controls.Add($CtrlBox)

function New-WinBtn($Text, $X, $Color, $Action) {
    $B = New-Object System.Windows.Forms.Button -Property @{
        Text = $Text; Size = New-Object System.Drawing.Size(40, 32); 
        Location = New-Object System.Drawing.Point($X, 14); FlatStyle = "Flat"; 
        ForeColor = $script:Theme.TextMuted; Tag = $Color
    }
    $B.FlatAppearance.BorderSize = 0
    $B.Add_Click($Action)
    $B.Add_MouseEnter({ $this.BackColor = $this.Tag; $this.ForeColor = [System.Drawing.Color]::White })
    $B.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::Transparent; $this.ForeColor = $script:Theme.TextMuted })
    $CtrlBox.Controls.Add($B)
}
New-WinBtn "✕" 105 $script:Theme.Danger { $Form.Close() }
New-WinBtn "⬜" 60 $script:Theme.CardHover { if ($Form.WindowState -eq "Maximized") { $Form.WindowState = "Normal" } else { $Form.WindowState = "Maximized" } }
New-WinBtn "—" 15 $script:Theme.CardHover { $Form.WindowState = "Minimized" }

# --- [Dashboard Area] ---
$MainArea = New-Object System.Windows.Forms.Panel -Property @{Dock="Fill"; Padding=New-Object System.Windows.Forms.Padding(0)}
$Form.Controls.Add($MainArea)

$script:DashView = New-Object System.Windows.Forms.Panel -Property @{Dock="Fill"; AutoScroll=$true}
$MainArea.Controls.Add($script:DashView)

# --- [Terminal] ---
$LogContainer = New-Object System.Windows.Forms.Panel -Property @{Dock="Bottom"; Height=220; BackColor=$script:Theme.Bg; Padding=New-Object System.Windows.Forms.Padding(30, 10, 30, 30)}
$Form.Controls.Add($LogContainer)

$LogBox = New-Object System.Windows.Forms.RichTextBox -Property @{
    Dock = "Fill"; BackColor = [System.Drawing.Color]::FromArgb(5, 5, 5);
    ForeColor = $script:Theme.TextMain; BorderStyle = "None"; ReadOnly = $true;
    Font = New-Object System.Drawing.Font("Consolas", 10)
}
$LogContainer.Controls.Add($LogBox)

$BtnClearLog = New-Object System.Windows.Forms.Button -Property @{
    Text = "CLEAR"; Size = New-Object System.Drawing.Size(60, 22); 
    FlatStyle = "Flat"; BackColor = $script:Theme.Header; ForeColor = $script:Theme.TextMuted;
    Font = New-Object System.Drawing.Font($GlobalFont, 7); Anchor = [System.Windows.Forms.AnchorStyles]"Bottom, Right"
}
$BtnClearLog.Location = New-Object System.Drawing.Point(1160, 10)
$BtnClearLog.FlatAppearance.BorderSize = 0
$BtnClearLog.Add_Click({ $LogBox.Clear() })
$LogContainer.Controls.Add($BtnClearLog)
$BtnClearLog.BringToFront()

function Write-Log ($Msg, $Type = "Info") {
    $LogBox.Invoke([Action[string, string]]{
        param($m, $t)
        $LogBox.SelectionStart = $LogBox.TextLength
        $LogBox.SelectionColor = switch ($t) {
            "Success" { $script:Theme.Success }
            "Warning" { $script:Theme.Warning }
            "Error"   { $script:Theme.Danger }
            Default   { $script:Theme.AccentGlow }
        }
        $LogBox.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] » $m`n")
        $LogBox.ScrollToCaret()
    }, $Msg, $Type)
}

# --- [Dashboard Layout Engine] ---
$global:LastY = 20
$global:Col = 0

function New-Section ($Title) {
    if ($global:Col -ne 0) { $global:LastY += 140 }
    $global:Col = 0
    $L = New-Object System.Windows.Forms.Label -Property @{
        Text = $Title.ToUpper(); Location = New-Object System.Drawing.Point(35, $global:LastY);
        Size = New-Object System.Drawing.Size(900, 30); ForeColor = $script:Theme.TextMuted;
        Font = New-Object System.Drawing.Font($GlobalFont, 9, [System.Drawing.FontStyle]::Bold)
    }
    $script:DashView.Controls.Add($L)
    $global:LastY += 40
}

function New-Tweak ($Title, $Desc, $Action) {
    $X = 35 + ($global:Col * 320)
    $P = New-Object System.Windows.Forms.Panel -Property @{
        Size = New-Object System.Drawing.Size(305, 125); BackColor = $script:Theme.Card;
        Location = New-Object System.Drawing.Point($X, $global:LastY)
    }
    $B = New-Object System.Windows.Forms.Button -Property @{
        Text = $Title; Dock = "Top"; Height = 65; FlatStyle = "Flat"; ForeColor = $script:Theme.TextMain; 
        Font = New-Object System.Drawing.Font($GlobalFont, 10, [System.Drawing.FontStyle]::Bold); TextAlign = "MiddleLeft";
        Padding = New-Object System.Windows.Forms.Padding(15, 0, 0, 0)
    }
    $B.FlatAppearance.BorderSize = 0
    $B.Add_MouseEnter({ $this.Parent.BackColor = $script:Theme.CardHover; $this.ForeColor = $script:Theme.AccentGlow })
    $B.Add_MouseLeave({ $this.Parent.BackColor = $script:Theme.Card; $this.ForeColor = $script:Theme.TextMain })
    $B.Add_Click($Action)
    $L = New-Object System.Windows.Forms.Label -Property @{
        Text = $Desc; Dock = "Bottom"; Height = 55; ForeColor = $script:Theme.TextMuted;
        Font = New-Object System.Drawing.Font($GlobalFont, 8); Padding = New-Object System.Windows.Forms.Padding(15, 0, 10, 0)
    }
    $P.Controls.AddRange(@($L, $B))
    $script:DashView.Controls.Add($P)
    $global:Col++
    if ($global:Col -eq 3) { $global:Col = 0; $global:LastY += 140 }
}

# --- [TWEAK POPULATION] ---
New-Section "Maintenance & Repair"
New-Tweak "Deep Repair" "DISM / SFC restoration cycle." { 
    Write-Log "Repair started..." "Warning"; sfc /scannow; dism /online /cleanup-image /restorehealth; Write-Log "Integrity verified." "Success" 
}
New-Tweak "Software Sync" "Upgrades all installed Winget packages." { 
    Write-Log "Syncing..." "Warning"; winget upgrade --all --silent; Write-Log "Apps synced." "Success" 
}
New-Tweak "OS Patching" "Force install Windows Updates." { 
    Write-Log "Checking for Updates..." "Warning"
    if (-not (Get-Module -ListAvailable PSWindowsUpdate)) { Install-Module PSWindowsUpdate -Force -SkipPublisherCheck }
    Get-WindowsUpdate -Install -AcceptAll -AutoReboot:$false; Write-Log "Update cycle complete." "Success"
}
New-Tweak "Storage Sweep" "ReTrim SSD and clear temp files." { 
    Write-Log "Optimizing storage..." "Warning"; Optimize-Volume -DriveLetter C -ReTrim; cleanmgr /sagerun:1; Write-Log "Cleanup complete." "Success" 
}

New-Section "System Performance"
New-Tweak "Gaming Mode" "Ultimate Power & Low Latency UI." { 
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value 0
    Write-Log "Performance profile active." "Success"
}
New-Tweak "Visual Boost" "Disable Animations & Transparency." { 
    reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f | Out-Null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f | Out-Null
    Write-Log "Visual effects minimized for speed." "Success"
}
New-Tweak "CPU Lasso" "Priority boost for foreground apps." { 
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options" /v "CpuPriorityClass" /t REG_DWORD /d 3 /f | Out-Null
    Write-Log "CPU Threading optimized." "Success"
}

New-Section "Networking & Connectivity"
New-Tweak "TCP Accelerator" "Tuning TCP/IP global stack." { 
    netsh int tcp set global autotuninglevel=normal; netsh int tcp set global rss=enabled
    Write-Log "TCP stack optimized." "Success"
}
New-Tweak "Cloudflare DNS" "Forces 1.1.1.1 on all adapters." { 
    Get-NetAdapter | Where { $_.Status -eq "Up" } | ForEach {
        Set-DnsClientServerAddress -InterfaceAlias $_.Name -ServerAddresses ("1.1.1.1", "1.0.0.1")
        Set-DnsClientServerAddress -InterfaceAlias $_.Name -ServerAddresses ("2606:4700:4700::1111", "2606:4700:4700::1001") -AddressFamily IPv6
    }
    Write-Log "Cloudflare DNS applied." "Success"
}
New-Tweak "DB LAN Fix" "SMB/Oplocks for DB stability." { 
    Set-SmbClientConfiguration -EnableSecuritySignature $false -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "EnableOplocks" -Value 0
    Write-Log "Database LAN hardened." "Success"
}

New-Section "Power & Hardware"
New-Tweak "Kill Hibernation" "Disables Hibernation to free space." { powercfg -h off; Write-Log "Hibernation disabled." "Success" }
New-Tweak "Never Sleep" "Prevents LAN timeout on AC power." { 
    powercfg -change -standby-timeout-ac 0; powercfg -change -monitor-timeout-ac 0
    Write-Log "AC Power timeouts removed." "Success" 
}
New-Tweak "Battery Health" "Generate Battery Diagnostic Report." { 
    $Path = "$env:USERPROFILE\Desktop\BatteryReport.html"
    powercfg /batteryreport /output $Path; Write-Log "Report saved to Desktop." "Success" 
}

New-Section "Admin & Privacy"
New-Tweak "Print Fixer" "Reset Spooler & Clear Queue." { 
    Stop-Service Spooler -Force; Remove-Item "$env:SystemRoot\System32\Spool\Printers\*" -Force; Start-Service Spooler
    Write-Log "Printer services restored." "Success"
}
New-Tweak "OEM Debloat" "Nukes TikTok, Disney, Meta, etc." { 
    $Apps = @("*TikTok*", "*Instagram*", "*Facebook*", "*Disney*", "*PrimeVideo*")
    foreach ($a in $Apps) { Get-AppxPackage $a | Remove-AppxPackage -ErrorAction SilentlyContinue }
    Write-Log "Bloatware purged." "Success"
}
New-Tweak "Recall Nuclear" "Total removal of AI Recall feature." { 
    Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -Remove -NoRestart
    Write-Log "AI Tracking removed." "Success"
}

# --- [Resize/Drag Logic] ---
$global:Dragging = $false; $global:Resizing = $false; $global:MousePos = New-Object System.Drawing.Point
$Grip = New-Object System.Windows.Forms.Panel -Property @{Size=New-Object System.Drawing.Size(20,20); Cursor="SizeNWSE"}
$Grip.Anchor = [System.Windows.Forms.AnchorStyles]"Bottom, Right"
$Grip.Location = New-Object System.Drawing.Point(([int]$Form.Width - 20), ([int]$Form.Height - 20))
$Form.Controls.Add($Grip); $Grip.BringToFront()

$Grip.Add_MouseDown({ $global:Resizing = $true; $global:MousePos = [System.Windows.Forms.Cursor]::Position })
$Grip.Add_MouseUp({ $global:Resizing = $false })
$Header.Add_MouseDown({ $global:Dragging = $true; $global:MousePos = $Form.PointToClient([System.Windows.Forms.Cursor]::Position) })
$Header.Add_MouseUp({ $global:Dragging = $false })

$Timer = New-Object System.Windows.Forms.Timer -Property @{Interval=1000; Enabled=$true}
$Timer.Add_Tick({
    $Boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $Span = (Get-Date) - $Boot
    $UptimeLbl.Text = "UPTIME: $($Span.Days)d $($Span.Hours)h $($Span.Minutes)m"
})

$DragTimer = New-Object System.Windows.Forms.Timer -Property @{Interval=10; Enabled=$true}
$DragTimer.Add_Tick({
    if ($global:Dragging) { $Form.Location = [System.Drawing.Point]::Subtract([System.Windows.Forms.Cursor]::Position, $global:MousePos) }
    if ($global:Resizing) {
        $CP = [System.Windows.Forms.Cursor]::Position
        $NewWidth = [int]($CP.X - $Form.Left); $NewHeight = [int]($CP.Y - $Form.Top)
        if ($NewWidth -ge 1100 -and $NewHeight -ge 900) { $Form.Size = New-Object System.Drawing.Size($NewWidth, $NewHeight) }
    }
})

[void]$Form.ShowDialog()
