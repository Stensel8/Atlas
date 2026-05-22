#Requires -Version 5.1 -RunAsAdministrator

param (
    [switch]$Silent
)
$ErrorActionPreference = 'Stop'

Set-StrictMode -Version 3.0

$windir = [Environment]::GetFolderPath('Windows')
Import-Module (Join-Path $windir 'AtlasModules\Scripts\Modules\Qol\Qol.psm1') -Force

# Disable network items
Get-NetAdapterBinding -Name '*' -ComponentID ms_msclient, ms_server, ms_lltdio, ms_rspndr -ErrorAction SilentlyContinue |
    Disable-NetAdapterBinding -ErrorAction SilentlyContinue |
    Out-Null

# Disable NetBios over TCP/IP
$interfaces = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.GetValue('NetbiosOptions') -ne $null }
foreach ($interface in $interfaces) {
    Set-ItemProperty -Path $interface.PSPath -Name 'NetbiosOptions' -Value 2 | Out-Null
}

# Disable NetBIOS service
Set-Service -Name NetBT -StartupType Disabled

# Set network profile to 'Public Network'
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Public

# Disable network discovery firewall rules
Get-NetFirewallRule | Where-Object {
    (
        ($_.Group -eq '@FirewallAPI.dll,-28502' -or $_.Group -eq '@FirewallAPI.dll,-32752') -or
        ($_.DisplayGroup -eq 'File and Printer Sharing' -or $_.DisplayGroup -eq 'Network Discovery')
    ) -and
    ($_.Profile -like '*Private*')
} | Disable-NetFirewallRule

Disable-NetworkNavigationPaneInExplorer
Disable-GiveAccessToContextMenu

if ($Silent) { exit }

Write-Host "`nCompleted! " -ForegroundColor Green -NoNewLine
Write-Host "You'll need to restart to apply the changes." -ForegroundColor Yellow
exit
