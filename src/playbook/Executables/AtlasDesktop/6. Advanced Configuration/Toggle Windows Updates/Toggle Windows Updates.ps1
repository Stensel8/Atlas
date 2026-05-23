#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$stateKey = 'HKLM:\SOFTWARE\AtlasOS\Services\ToggleWindowsUpdates'
if (-not (Test-Path -LiteralPath $stateKey)) { New-Item -Path $stateKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $stateKey -Name 'path' -Value $PSCommandPath -Type String

$wuSvc = Get-Service -Name 'wuauserv' -ErrorAction SilentlyContinue
$isDisabled = $wuSvc -and $wuSvc.StartType -eq 'Disabled'

$currentLabel = if ($isDisabled) { ' (current)' } else { '' }
$enableLabel  = if (-not $isDisabled) { ' (current)' } else { '' }

$choice = $Host.UI.PromptForChoice(
    'Windows Update Toggle',
    '',
    @("1. Disable Windows Updates$currentLabel", "2. Enable Windows Updates$enableLabel"),
    -1
)

if ($choice -eq 0) {
    Write-Output 'Disabling Windows Update service and scheduled tasks...'
    & sc.exe stop  wuauserv    2>$null | Out-Null
    & sc.exe config wuauserv start= disabled 2>$null | Out-Null
    & sc.exe stop  UsoSvc     2>$null | Out-Null
    & sc.exe config UsoSvc start= disabled 2>$null | Out-Null

    $medicKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc'
    if (-not (Test-Path -LiteralPath $medicKey)) { New-Item -Path $medicKey -Force | Out-Null }
    Set-ItemProperty -LiteralPath $medicKey -Name 'Start' -Value 4 -Type DWord
    & sc.exe stop WaaSMedicSvc 2>$null | Out-Null

    foreach ($task in @(
        '\Microsoft\Windows\WindowsUpdate\sih'
        '\Microsoft\Windows\WindowsUpdate\sihboot'
        '\Microsoft\Windows\UpdateOrchestrator\Schedule Scan'
        '\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker'
        '\Microsoft\Windows\UpdateOrchestrator\Reboot'
    )) {
        & schtasks.exe /Change /TN $task /Disable 2>$null | Out-Null
    }

    $wuKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    if (-not (Test-Path -LiteralPath $wuKey)) { New-Item -Path $wuKey -Force | Out-Null }
    Set-ItemProperty -LiteralPath $wuKey -Name 'DisableWindowsUpdateAccess' -Value 1 -Type DWord
    Set-ItemProperty -LiteralPath $wuKey -Name 'DoNotConnectToWindowsUpdateInternetLocations' -Value 1 -Type DWord
    $auKey = "$wuKey\AU"
    if (-not (Test-Path -LiteralPath $auKey)) { New-Item -Path $auKey -Force | Out-Null }
    Set-ItemProperty -LiteralPath $auKey -Name 'NoAutoUpdate' -Value 1 -Type DWord

    Invoke-AtlasSettingsPage -Operation hide -Page 'windowsupdate'
    Set-ItemProperty -LiteralPath $stateKey -Name 'state' -Value 0 -Type DWord

    Write-Output 'Windows Updates have been disabled.'

} else {
    Write-Output 'Enabling Windows Update service and scheduled tasks...'
    & sc.exe config wuauserv start= demand 2>$null | Out-Null
    & sc.exe start  wuauserv 2>$null | Out-Null
    & sc.exe config UsoSvc start= demand 2>$null | Out-Null
    & sc.exe start  UsoSvc  2>$null | Out-Null

    $medicKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc'
    if (-not (Test-Path -LiteralPath $medicKey)) { New-Item -Path $medicKey -Force | Out-Null }
    Set-ItemProperty -LiteralPath $medicKey -Name 'Start' -Value 3 -Type DWord
    & sc.exe start WaaSMedicSvc 2>$null | Out-Null

    foreach ($task in @(
        '\Microsoft\Windows\WindowsUpdate\sih'
        '\Microsoft\Windows\WindowsUpdate\sihboot'
        '\Microsoft\Windows\UpdateOrchestrator\Schedule Scan'
        '\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker'
        '\Microsoft\Windows\UpdateOrchestrator\Reboot'
    )) {
        & schtasks.exe /Change /TN $task /Enable 2>$null | Out-Null
    }

    $wuKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    Remove-ItemProperty -LiteralPath $wuKey -Name 'DisableWindowsUpdateAccess' -ErrorAction SilentlyContinue
    Remove-ItemProperty -LiteralPath $wuKey -Name 'DoNotConnectToWindowsUpdateInternetLocations' -ErrorAction SilentlyContinue
    Remove-ItemProperty -LiteralPath "$wuKey\AU" -Name 'NoAutoUpdate' -ErrorAction SilentlyContinue

    Invoke-AtlasSettingsPage -Operation unhide -Page 'windowsupdate'
    Set-ItemProperty -LiteralPath $stateKey -Name 'state' -Value 1 -Type DWord

    Write-Output 'Windows Updates have been enabled.'
}

Write-Output ''
$reboot = $Host.UI.PromptForChoice('', 'Would you like to reboot now to apply changes?', @('&Yes', '&No'), 1)
if ($reboot -eq 0) { & shutdown.exe /r /t 0 }
