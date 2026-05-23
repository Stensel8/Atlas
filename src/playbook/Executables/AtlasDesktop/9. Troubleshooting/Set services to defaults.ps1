#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$servicesPath = Join-Path $env:windir 'AtlasDesktop\6. Advanced Configuration\Services'
if (-not (Test-Path -LiteralPath $servicesPath -PathType Container)) {
    throw "Services folder not found: '$servicesPath'"
}

if (-not $Silent) {
    Write-Output 'This will reset the configuration of services in the Atlas folder.'
    Write-Output 'Disabling services often breaks features, and if you are experiencing an issue, this might help.'
    Write-Output ''
    $confirm = $Host.UI.PromptForChoice('', 'Continue?', @('&Yes', '&No'), 1)
    if ($confirm -ne 0) { return }
}

Write-Output ''
Write-Output '----------------------------------------------'
Write-Output 'Enabling services... This might take a while.'
Write-Output '----------------------------------------------'

$defaults = Get-ChildItem -Path $servicesPath -Recurse -Filter '*(default)*.ps1' -ErrorAction SilentlyContinue
foreach ($script in $defaults) {
    Write-Output "Running '$($script.Name)'..."
    & $script.FullName -Silent
}

$atlasOther    = Join-Path $env:windir 'AtlasModules\Other'
$winServices   = Join-Path $atlasOther 'winServices.reg'
$atlasServices = Join-Path $atlasOther 'atlasServices.reg'

if (-not $Silent -and (Test-Path -LiteralPath $winServices) -and (Test-Path -LiteralPath $atlasServices)) {
    Write-Output ''
    $choice = $Host.UI.PromptForChoice('', 'What would you like to do?', @(
        '1. Restore a full services backup of the default Windows services',
        '2. Restore a full services backup of the default Atlas services',
        '3. Nothing'
    ), 2)
    switch ($choice) {
        0 { & reg.exe import $winServices   | Out-Null }
        1 { & reg.exe import $atlasServices | Out-Null }
    }
}

if ($Silent) { return }
Write-Output ''
$restart = $Host.UI.PromptForChoice('', 'A restart is required to apply the changes. Restart now?', @('&Yes', '&No'), 1)
if ($restart -eq 0) { Restart-Computer -Force }
