#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
# Atlas.Services domain functions: Startup

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

function Enable-NetworkDiscoveryServices {
    # LanmanWorkstation (SMB) is a hard dependency for network discovery
    Set-Service -Name 'LanmanWorkstation' -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name 'LanmanWorkstation' -ErrorAction SilentlyContinue

    Set-Service -Name 'eventlog'  -StartupType Automatic -ErrorAction SilentlyContinue
    Set-Service -Name 'fdPHost'   -StartupType Manual    -ErrorAction SilentlyContinue
    Set-Service -Name 'FDResPub'  -StartupType Manual    -ErrorAction SilentlyContinue
    Set-Service -Name 'lmhosts'   -StartupType Manual    -ErrorAction SilentlyContinue
    Set-Service -Name 'netman'    -StartupType Manual    -ErrorAction SilentlyContinue
    Set-Service -Name 'SSDPSRV'   -StartupType Manual    -ErrorAction SilentlyContinue

    # NlaSvc startup differs between Win10 and Win11
    $build = [int](Get-CimInstance -ClassName Win32_OperatingSystem -Property BuildNumber).BuildNumber
    $nlaSvcStartup = if ($build -lt 22000) { 'Automatic' } else { 'Manual' }
    Set-Service -Name 'NlaSvc' -StartupType $nlaSvcStartup -ErrorAction SilentlyContinue
}
