#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$script = Join-Path $env:windir 'AtlasModules\Scripts\Install-AtlasToolbox.ps1'
if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
    Write-Host "[!!] Script not found: '$script'" -ForegroundColor Red
    if (-not $Silent) { Read-Host 'Press Enter to exit' }
    exit 1
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script @activeArgs
