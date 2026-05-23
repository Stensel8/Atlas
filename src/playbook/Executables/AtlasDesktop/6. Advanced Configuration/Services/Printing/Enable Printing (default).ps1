#Requires -Version 5.1
param([switch]$Silent, [switch]$JustContext)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Printing' -State 1 -ScriptPath $PSCommandPath

if (-not $Silent -and -not $JustContext) { Show-AtlasServiceWarning }

$null = New-PSDrive -Name 'HKCR' -PSProvider Registry -Root 'HKEY_CLASSES_ROOT' -ErrorAction SilentlyContinue

if (-not $Silent) {
    Write-Output 'Enabling printing...'
    Write-Output ''
    $addPrint = $Host.UI.PromptForChoice('', "Would you like to add 'Print' to the context menu?", @('&Yes', '&No'), 1)
    if ($addPrint -eq 0) {
        Write-Output "Adding 'Print' to context menu..."

        Remove-ItemProperty -LiteralPath 'HKCR:\SystemFileAssociations\image\shell\print' `
            -Name 'ProgrammaticAccessOnly' -ErrorAction SilentlyContinue

        foreach ($class in @(
            'batfile','cmdfile','docxfile','fonfile','htmlfile','inffile','inifile',
            'JSEFile','otffile','pfmfile','regfile','rtffile','ttcfile','ttffile',
            'txtfile','VBEFile','VBSFile','WSFFile'
        )) {
            Remove-ItemProperty -LiteralPath "HKCR:\$class\shell\print" `
                -Name 'ProgrammaticAccessOnly' -ErrorAction SilentlyContinue
        }

        $build = [System.Environment]::OSVersion.Version.Build
        if ($build -ge 22000) {
            foreach ($sub in @('Print', 'PrintTo')) {
                $appxKey = "HKCR:\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\$sub"
                Remove-ItemProperty -LiteralPath $appxKey -Name 'LegacyDisable'          -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $appxKey -Name 'ProgrammaticAccessOnly' -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $appxKey -Name 'HideBasedOnVelocityId'  -ErrorAction SilentlyContinue
            }
        }
    }
}

if ($JustContext) { return }

Write-Output 'Enabling services...'
Set-AtlasServiceStartup -Name 'Spooler'              -Start 2
Set-AtlasServiceStartup -Name 'PrintWorkFlowUserSvc' -Start 3
Invoke-AtlasSettingsPage -Operation unhide -Page 'printers'

Write-Output 'Enabling features...'
foreach ($feature in @(
    'Printing-Foundation-Features'
    'Printing-Foundation-InternetPrinting-Client'
    'Printing-XPSServices-Features'
    'Printing-PrintToPDFServices-Features'
)) {
    & dism.exe /Online /Enable-Feature /FeatureName:$feature /NoRestart 2>&1 | Out-Null
}

Write-Output 'Enabling capabilities (this might take a while)...'
& dism.exe /Online /Add-Capability /CapabilityName:'Print.Management.Console~~~~0.0.1.0' /NoRestart 2>&1 | Out-Null

if ($Silent) { return }

$fax = $Host.UI.PromptForChoice('', 'Would you want to enable Fax and Scan functionality?', @('&Yes', '&No'), 1)
if ($fax -eq 0) {
    & dism.exe /Online /Add-Capability /CapabilityName:'Print.Fax.Scan~~~~0.0.1.0' /NoRestart 2>&1 | Out-Null
}

Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
