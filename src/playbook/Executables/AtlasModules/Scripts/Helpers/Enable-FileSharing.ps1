#Requires -Version 5.1 -RunAsAdministrator
$ErrorActionPreference = 'Stop'

Set-StrictMode -Version 3.0

$windir = [Environment]::GetFolderPath('Windows')
Import-Module (Join-Path $windir 'AtlasModules\Scripts\Modules\Qol\Qol.psm1')         -Force
Import-Module (Join-Path $windir 'AtlasModules\Scripts\Modules\Scripts\Scripts.psm1') -Force

# Enable network items
Enable-NetAdapterBinding -Name '*' -ComponentID ms_msclient, ms_server, ms_lltdio, ms_rspndr | Out-Null

# Enable Network Discovery services and dependencies
Enable-NetworkDiscoveryServices

# Enable NetBios over TCP/IP
$interfaces = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.GetValue('NetbiosOptions') -ne $null }
foreach ($interface in $interfaces) {
    Set-ItemProperty -Path $interface.PSPath -Name 'NetbiosOptions' -Value 1 | Out-Null
}

# Enable NetBIOS service
Set-Service -Name NetBT -StartupType System

$choices = @(
    [System.Management.Automation.Host.ChoiceDescription]::new('&Yes')
    [System.Management.Automation.Host.ChoiceDescription]::new('&No')
)

$answer = $Host.UI.PromptForChoice('', "Would you like to change your network profile to 'Private'?", $choices, 1)
if ($answer -eq 0) {
    Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

    Get-NetFirewallRule | Where-Object {
        (
            ($_.Group -eq '@FirewallAPI.dll,-28502' -or $_.Group -eq '@FirewallAPI.dll,-32752') -or
            ($_.DisplayGroup -eq 'File and Printer Sharing' -or $_.DisplayGroup -eq 'Network Discovery')
        ) -and
        ($_.Profile -like '*Private*')
    } | Enable-NetFirewallRule

    $null = New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private' -Name 'AutoSetup' -Value 1 | Out-Null
}

$answer = $Host.UI.PromptForChoice('', 'Would you like to add the Network Navigation Pane to the Explorer sidebar?', $choices, 1)
if ($answer -eq 0) {
    Enable-NetworkNavigationPaneInExplorer
}

$answer = $Host.UI.PromptForChoice('', "Would you like to restore the 'Give access to' context menu in Explorer?", $choices, 1)
if ($answer -eq 0) {
    Enable-GiveAccessToContextMenu
}

Write-Host "`nCompleted! " -ForegroundColor Green -NoNewLine
Write-Host "You'll need to restart to apply the changes." -ForegroundColor Yellow
exit
