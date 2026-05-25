#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'PSProfile' -State 1 -ScriptPath $PSCommandPath

function Install-WingetPackage {
    param([string]$Id, [string]$Label)
    Write-Output "  Installing $Label..."
    winget install --id $Id --source winget --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    if ($LASTEXITCODE -notin @(0, -1978335189)) {
        Write-Warning "  $Label install returned exit code $LASTEXITCODE — continuing"
    }
}

# Ensure winget is available
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error 'winget not found. Install App Installer from the Microsoft Store first.'
    if (-not $Silent) { $null = Read-Host 'Press Enter to exit' }
    exit 1
}

# Install dependencies
Write-Output 'Installing PowerShell profile dependencies...'
Install-WingetPackage 'JanDeDobbeleer.OhMyPosh'        'Oh My Posh'
Install-WingetPackage 'ajeetdsouza.zoxide'              'zoxide'
Install-WingetPackage 'DEVCOM.JetBrainsMonoNerdFont'    'JetBrainsMono Nerd Font'

# Copy Oh My Posh theme to AppData\AtlasOS
$atlasData = Join-Path $env:APPDATA 'AtlasOS'
if (-not (Test-Path -LiteralPath $atlasData)) { New-Item -Path $atlasData -ItemType Directory -Force | Out-Null }
$ompSrc = Join-Path $PSScriptRoot 'atlas.omp.json'
Copy-Item -LiteralPath $ompSrc -Destination (Join-Path $atlasData 'atlas.omp.json') -Force

# Determine PS7 profile path
$ps7Profile = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
$profileDir  = Split-Path $ps7Profile -Parent
if (-not (Test-Path -LiteralPath $profileDir)) { New-Item -Path $profileDir -ItemType Directory -Force | Out-Null }

# Back up existing profile if present and not already an Atlas backup
if ((Test-Path -LiteralPath $ps7Profile) -and -not (Test-Path -LiteralPath "$ps7Profile.atlasbak")) {
    Copy-Item -LiteralPath $ps7Profile -Destination "$ps7Profile.atlasbak" -Force
    Write-Output "  Backed up existing profile to $ps7Profile.atlasbak"
}

# Install Atlas profile
$profileSrc = Join-Path $PSScriptRoot 'Microsoft.PowerShell_profile.ps1'
Copy-Item -LiteralPath $profileSrc -Destination $ps7Profile -Force

if ($Silent) { return }

Write-Output ''
Write-Output 'Atlas PowerShell profile installed.'
Write-Output '  Restart PowerShell 7 to apply.'
Write-Output '  Tip: set JetBrainsMono Nerd Font in Windows Terminal for best experience.'
$null = Read-Host 'Press Enter to exit'
