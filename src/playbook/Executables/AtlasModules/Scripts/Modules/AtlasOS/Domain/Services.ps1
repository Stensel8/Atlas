#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
# AtlasOS domain functions: Services

function Set-AtlasServiceStartup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateRange(0, 4)][int]$Start
    )

    $servicePath = Join-Path -Path 'HKLM:\SYSTEM\CurrentControlSet\Services' -ChildPath $Name
    if (-not (Test-Path -LiteralPath $servicePath)) {
        Write-Warning "Service or driver '$Name' was not found."
        return
    }
    Set-ItemProperty -LiteralPath $servicePath -Name 'Start' -Value $Start -Type DWord
}

function Show-AtlasServiceWarning {
    [CmdletBinding()]
    param([string]$Note)

    Write-Host '------------------------------------------------------' -ForegroundColor Yellow
    Write-Host 'WARNING: This script will modify system services.' -ForegroundColor Yellow
    Write-Host 'Modifying services can lead to potential breakage of features and bugs.' -ForegroundColor Yellow
    Write-Host 'Proceed with caution, and refer to Atlas docs for more information!' -ForegroundColor Yellow
    if ($Note) { Write-Host "Specific Note: $Note" -ForegroundColor Yellow }
    Write-Host '------------------------------------------------------' -ForegroundColor Yellow
    $null = Read-Host 'Press Enter to continue'
}
