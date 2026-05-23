#Requires -Version 5.1
# Atlas installation diagnostics
# Collects system, Atlas, and feature info for issue reporting.
# Copy the full output and paste it when filing a bug report.

param([switch]$Silent)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs -Wait
    } catch {
        Write-Host '[!!] Run as Administrator for full output.' -ForegroundColor Red
        Read-Host 'Press Enter to exit'
        exit 1
    }
    exit 0
}

function Show-PathStatus($label, $path) {
    $exists = Test-Path $path
    $color = if ($exists) { 'Green' } else { 'Red' }
    Write-Host "[$( if ($exists) {'OK'} else {'--'} )] $label" -ForegroundColor $color
    if ($exists -and (Test-Path $path -PathType Container)) {
        $items = Get-ChildItem $path -ErrorAction SilentlyContinue
        if ($items) { $items | ForEach-Object { Write-Host "       $_" -ForegroundColor DarkGray } }
    }
}

# ── System ────────────────────────────────────────────────────────────────────
Write-Host "`n=== System Information ===" -ForegroundColor Cyan
try {
    $os  = Get-CimInstance Win32_OperatingSystem
    $cs  = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    Write-Host "    OS      : $($os.Caption)"
    Write-Host "    Build   : $($os.BuildNumber)  ($($os.Version))"
    Write-Host "    Arch    : $($os.OSArchitecture)"
    Write-Host "    CPU     : $($cpu.Name.Trim())"
    Write-Host "    RAM     : $([math]::Round($cs.TotalPhysicalMemory / 1GB, 1)) GB"
} catch {
    Write-Host "    [!!] Failed to collect system info: $_" -ForegroundColor Red
}

Write-Host "`n=== Disk Space ===" -ForegroundColor Cyan
Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue |
    Where-Object { $_.Used -gt 0 } |
    ForEach-Object {
        $total = [math]::Round(($_.Used + $_.Free) / 1GB, 1)
        $free  = [math]::Round($_.Free / 1GB, 1)
        Write-Host "    $($_.Name): $free GB free of $total GB"
    }

# ── AME Wizard ────────────────────────────────────────────────────────────────
Write-Host "`n=== AME Wizard Logs ===" -ForegroundColor Cyan
Show-PathStatus 'AppData\Local\AME Wizard Beta'   "$env:LOCALAPPDATA\AME Wizard Beta"
Show-PathStatus 'AppData\Roaming\AME Wizard Beta' "$env:APPDATA\AME Wizard Beta"
Show-PathStatus 'C:\AME'                          'C:\AME'
Show-PathStatus 'C:\ProgramData\AME'             'C:\ProgramData\AME'
Show-PathStatus 'C:\Windows\Temp (AME files)'    'C:\Windows\Temp'

# ── Atlas modules ─────────────────────────────────────────────────────────────
Write-Host "`n=== Atlas Modules ===" -ForegroundColor Cyan
Show-PathStatus 'C:\Windows\AtlasModules'  'C:\Windows\AtlasModules'
Show-PathStatus 'C:\Windows\AtlasDesktop'  'C:\Windows\AtlasDesktop'

# ── RunOnce keys ──────────────────────────────────────────────────────────────
Write-Host "`n=== RunOnce keys ===" -ForegroundColor Cyan
Write-Host '[HKLM RunOnce]' -ForegroundColor Yellow
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -ErrorAction SilentlyContinue |
    Select-Object * -ExcludeProperty PS* | Format-List
Write-Host '[HKCU RunOnce]' -ForegroundColor Yellow
Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -ErrorAction SilentlyContinue |
    Select-Object * -ExcludeProperty PS* | Format-List

# ── Atlas version ─────────────────────────────────────────────────────────────
Write-Host "`n=== Atlas Version ===" -ForegroundColor Cyan
$oem = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' -ErrorAction SilentlyContinue
if ($oem) {
    Write-Host "    Manufacturer : $($oem.Manufacturer)"
    Write-Host "    Model        : $($oem.Model)"
    Write-Host "    SupportURL   : $($oem.SupportURL)"
} else {
    Write-Host '    [--] OEM info not set' -ForegroundColor Red
}

# ── Atlas feature states ──────────────────────────────────────────────────────
Write-Host "`n=== Atlas Feature States ===" -ForegroundColor Cyan
if (Test-Path 'HKLM:\SOFTWARE\AtlasOS\Services') {
    Get-ChildItem 'HKLM:\SOFTWARE\AtlasOS\Services' -ErrorAction SilentlyContinue | ForEach-Object {
        $featureName = Split-Path $_.Name -Leaf
        $state = (Get-ItemProperty $_.PSPath -Name 'state' -ErrorAction SilentlyContinue).state
        $stateStr = switch ($state) {
            0 { 'disabled' }
            1 { 'enabled' }
            default { if ($null -ne $state) { $state } else { '?' } }
        }
        Write-Host "    $featureName : $stateStr" -ForegroundColor DarkGray
    }
} else {
    Write-Host '    [--] HKLM:\SOFTWARE\AtlasOS\Services missing' -ForegroundColor Red
}

Write-Host "`n=== Atlas SetupOptions ===" -ForegroundColor Cyan
$setup = Get-ItemProperty 'HKLM:\SOFTWARE\AtlasOS\SetupOptions' -ErrorAction SilentlyContinue
if ($setup) {
    $setup | Select-Object * -ExcludeProperty PS* | Format-List
} else {
    Write-Host '    [--] SetupOptions key missing' -ForegroundColor Red
}

# ── Key optional features ─────────────────────────────────────────────────────
Write-Host "`n=== Key Optional Features ===" -ForegroundColor Cyan
$optFeatures = @(
    'WindowsMediaPlayer',
    'WorkFolders-Client',
    'MicrosoftWindowsPowerShellISE',
    'Internet-Explorer-Optional-amd64'
)
foreach ($f in $optFeatures) {
    $feat = Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction SilentlyContinue
    if ($feat) {
        $color = if ($feat.State -eq 'Disabled') { 'Green' } else { 'Yellow' }
        Write-Host "    $f : $($feat.State)" -ForegroundColor $color
    } else {
        Write-Host "    $f : not present" -ForegroundColor DarkGray
    }
}

Write-Host "`n=== Key Capabilities ===" -ForegroundColor Cyan
$caps = @(
    'Media.WindowsMediaPlayer~~~~0.0.12.0',
    'Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0',
    'Microsoft.Windows.Notepad.System~~~~0.0.1.0',
    'Browser.InternetExplorer~~~~0.0.11.0',
    'Microsoft.Windows.Extended.Themes~~~~0.0.1.0',
    'VBSCRIPT~~~~'
)
foreach ($c in $caps) {
    $cap = Get-WindowsCapability -Online -Name $c -ErrorAction SilentlyContinue
    if ($cap) {
        $color = if ($cap.State -eq 'NotPresent') { 'Green' } else { 'Yellow' }
        Write-Host "    $c : $($cap.State)" -ForegroundColor $color
    } else {
        Write-Host "    $c : not found" -ForegroundColor DarkGray
    }
}

# ── Pending reboot ────────────────────────────────────────────────────────────
Write-Host "`n=== Pending Reboot ===" -ForegroundColor Cyan
$pending = $false
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') { $pending = $true }
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') { $pending = $true }
if (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue) { $pending = $true }
Write-Host "    Pending reboot : $pending"

# ── Scheduled tasks ───────────────────────────────────────────────────────────
Write-Host "`n=== Scheduled Tasks (AME/Atlas) ===" -ForegroundColor Cyan
Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskName -match 'AME|Atlas|ame' } |
    Format-Table TaskName, State, TaskPath -AutoSize

# ── Boot entry ────────────────────────────────────────────────────────────────
Write-Host "`n=== Boot Entry ===" -ForegroundColor Cyan
& bcdedit /enum '{current}' 2>&1 | Select-String 'description|safeboot'

Write-Host "`nDone. Copy the full output above and paste it when filing a bug report." -ForegroundColor Cyan
if (-not $Silent) { Read-Host 'Press Enter to exit' }
