#Requires -Version 5.1
param([switch]$Silent, [switch]$JustContext)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

# HKCR: is not a built-in PowerShell drive (unlike HKLM: and HKCU:), map it explicitly.
if (-not (Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
}

Set-AtlasSettingState -SettingName 'Printing' -State 0 -ScriptPath $PSCommandPath

if (-not $Silent -and -not $JustContext) { Show-AtlasServiceWarning }

Write-Output 'Removing Print from context menus...'
$key = 'HKCR:\SystemFileAssociations\image\shell\print'
if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
New-ItemProperty -LiteralPath $key -Name 'ProgrammaticAccessOnly' -Value '' -PropertyType String -Force | Out-Null

foreach ($class in @(
    'batfile', 'cmdfile', 'docxfile', 'fonfile', 'htmlfile', 'inffile', 'inifile',
    'JSEFile', 'otffile', 'pfmfile', 'regfile', 'rtffile', 'ttcfile', 'ttffile',
    'txtfile', 'VBEFile', 'VBSFile', 'WSFFile'
)) {
    $printKey = "HKCR:\$class\shell\print"
    if (-not (Test-Path -LiteralPath $printKey)) { New-Item -Path $printKey -Force | Out-Null }
    New-ItemProperty -LiteralPath $printKey -Name 'ProgrammaticAccessOnly' -Value '' -PropertyType String -Force | Out-Null
}

$build = [System.Environment]::OSVersion.Version.Build
if ($build -ge 22000) {
    foreach ($subKey in @('Print', 'PrintTo')) {
        $appxKey = "HKCR:\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\$subKey"
        if (-not (Test-Path -LiteralPath $appxKey)) { New-Item -Path $appxKey -Force | Out-Null }
        New-ItemProperty -LiteralPath $appxKey -Name 'LegacyDisable'          -Value '' -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $appxKey -Name 'ProgrammaticAccessOnly' -Value '' -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $appxKey -Name 'HideBasedOnVelocityId'  -Value 6527944 -PropertyType DWord -Force | Out-Null
    }
}

if ($JustContext) { return }

Write-Output 'Disabling services...'
Set-AtlasServiceStartup -Name 'Spooler'               -Start 4
Set-AtlasServiceStartup -Name 'PrintWorkFlowUserSvc'  -Start 4
Invoke-AtlasSettingsPage -Operation hide -Page 'printers'

Write-Output 'Disabling features...'
foreach ($feature in @(
    'Printing-Foundation-Features'
    'Printing-Foundation-InternetPrinting-Client'
    'Printing-XPSServices-Features'
    'Printing-PrintToPDFServices-Features'
)) {
    & dism.exe /Online /Disable-Feature /FeatureName:$feature /NoRestart 2>&1 | Out-Null
}

if ($Silent) { return }

Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
