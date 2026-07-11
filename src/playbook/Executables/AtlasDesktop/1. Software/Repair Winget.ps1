#Requires -Version 5.1
# Repairs Windows Package Manager (winget) via asheroto/winget-install from PSGallery.
# Credits: @asheroto -- https://github.com/asheroto/winget-install

param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

if (-not $Silent) {
    Write-Host ''
    Write-Host '  Repairing winget using winget-install (PSGallery)' -ForegroundColor Cyan
    Write-Host '  Credits: @asheroto -- https://github.com/asheroto/winget-install' -ForegroundColor DarkGray
    Write-Host ''
}

try {
    Write-Host '[>>] Installing winget-install script from PSGallery...' -ForegroundColor Yellow
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Where-Object { $_.Version -ge '2.8.5.201' })) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }
    Install-Script -Name winget-install -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
    Write-Host '[OK] Script installed.' -ForegroundColor Green

    Write-Host '[>>] Running winget-install (this may take a moment)...' -ForegroundColor Yellow
    $installed = Get-InstalledScript 'winget-install' -ErrorAction SilentlyContinue
    if ($null -eq $installed) { throw 'winget-install script not found after PSGallery install.' }

    $scriptFile = Join-Path $installed.InstalledLocation 'winget-install.ps1'
    # winget-install calls exit internally — run in a child process to keep this session alive
    $ps = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
    $result = Start-Process $ps -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptFile`" -Force" -Wait -PassThru

    if ($result.ExitCode -eq 0) {
        Write-Host '[OK] Winget repair complete.' -ForegroundColor Green
    } else {
        Write-Host "[!!] Repair exited with code $($result.ExitCode)." -ForegroundColor Red
        if (-not $Silent) { $null = Read-Host 'Press Enter to exit' }
        exit $result.ExitCode
    }
} catch {
    Write-Host "[!!] Failed to repair winget: $_" -ForegroundColor Red
    if (-not $Silent) { $null = Read-Host 'Press Enter to exit' }
    exit 1
}

Write-Host ''
if (-not $Silent) { $null = Read-Host 'Press Enter to exit' }
