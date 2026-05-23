#Requires -Version 5.1
param([switch]$Silent, [switch]$JustContext)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'FileSharing' -State 0 -ScriptPath $PSCommandPath

$internalScript = Join-Path $env:windir 'AtlasModules\Scripts\Helpers\DisableFileSharing.ps1'
if (-not (Test-Path -LiteralPath $internalScript -PathType Leaf)) {
    throw "Atlas internal script '$internalScript' is missing."
}

$passArgs = @()
if ($Silent)      { $passArgs += '-Silent' }
if ($JustContext) { $passArgs += '-JustContext' }
& $internalScript @passArgs

if ($JustContext -or $Silent) { return }

$choice = $Host.UI.PromptForChoice('', 'Would you like to restart now to apply the changes?', @('&Yes', '&No'), 1)
if ($choice -eq 0) { & shutdown.exe /r /t 0 }

Write-Output ''
Write-Output 'File Sharing is now disabled.'
$null = Read-Host 'Press Enter to exit'
