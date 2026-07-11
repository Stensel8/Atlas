#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$servicesPath = Join-Path $env:windir 'AtlasDesktop\6. Advanced Configuration\Services'
if (-not (Test-Path -LiteralPath $servicesPath -PathType Container)) {
    throw "Services folder not found: '$servicesPath'"
}

if (-not $Silent) {
    Write-Host 'This will reset the configuration of services in the Atlas folder.' -ForegroundColor White
    Write-Host 'Disabling services often breaks features, and if you are experiencing an issue, this might help.' -ForegroundColor White
    Write-Host ''
    $confirm = $Host.UI.PromptForChoice('', 'Continue?', @('&Yes', '&No'), 1)
    if ($confirm -ne 0) { return }
}

Write-Host ''
Write-Host '[>>] Enabling services... This might take a while.' -ForegroundColor Yellow

$defaults = Get-ChildItem -Path $servicesPath -Recurse -Filter '*(default)*.ps1' -ErrorAction SilentlyContinue
foreach ($script in $defaults) {
    Write-Host "  Running '$($script.Name)'..." -ForegroundColor DarkGray
    & $script.FullName -Silent
}

$atlasOther    = Join-Path $env:windir 'AtlasModules\Other'
$winServices   = Join-Path $atlasOther 'winServices.reg'
$atlasServices = Join-Path $atlasOther 'atlasServices.reg'

if (-not $Silent -and (Test-Path -LiteralPath $winServices) -and (Test-Path -LiteralPath $atlasServices)) {
    Write-Host ''
    $choice = $Host.UI.PromptForChoice('', 'What would you like to do?', @(
        '1. Restore a full services backup of the default Windows services',
        '2. Restore a full services backup of the default Atlas services',
        '3. Nothing'
    ), 2)
    switch ($choice) {
        0 {
            Write-Host '[>>] Importing Windows services backup...' -ForegroundColor Yellow
            & reg.exe import $winServices | Out-Null
            Write-Host '[OK] Windows services backup restored.' -ForegroundColor Green
        }
        1 {
            Write-Host '[>>] Importing Atlas services backup...' -ForegroundColor Yellow
            & reg.exe import $atlasServices | Out-Null
            Write-Host '[OK] Atlas services backup restored.' -ForegroundColor Green
        }
    }
}

if ($Silent) { return }
Write-Host ''
$restart = $Host.UI.PromptForChoice('', 'A restart is required to apply the changes. Restart now?', @('&Yes', '&No'), 1)
if ($restart -eq 0) { Restart-Computer -Force }
