#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Repair Winget
# Attempts to repair or reinstall Windows Package Manager (winget).
# Uses AppX re-registration first, then falls back to asheroto/winget-install
# via PSGallery (https://github.com/asheroto/winget-install).
# ============================================================================

param(
    [switch]$Silent
)

$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Silent) { $argList += ' -Silent' }
    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs -Wait
    } catch {
        Write-Host '[!!] Administrator privileges are required.' -ForegroundColor Red
        if (-not $Silent) { Read-Host 'Press Enter to exit' }
        exit 1
    }
    exit 0
}

function Test-WingetWorking {
    try {
        $null = & winget --version 2>&1
        return $LASTEXITCODE -eq 0
    } catch { return $false }
}

try {
    if (Test-WingetWorking) {
        if (-not $Silent) {
            Write-Host '[OK] winget is working.' -ForegroundColor Green
            $choice = Read-Host 'Reinstall winget anyway? (y/N)'
            if ($choice -notmatch '^[Yy]') {
                exit 0
            }
            Write-Host '[..] Proceeding with reinstall...' -ForegroundColor Yellow
        } else {
            exit 0
        }
    } else {
        Write-Host '[..] winget not working, attempting repair...' -ForegroundColor Yellow
    }

    # Step 1: re-register the AppX package (fast, no internet needed)
    try {
        Write-Host '[..] Re-registering Microsoft.DesktopAppInstaller...' -ForegroundColor Yellow
        Add-AppxPackage -RegisterByFamilyName -MainPackage 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe' -ErrorAction Stop
        Start-Sleep -Seconds 2
        if (Test-WingetWorking) {
            if (-not $Silent) {
                Write-Host '[OK] winget repaired via AppX re-registration.' -ForegroundColor Green
                Read-Host 'Press Enter to exit'
            }
            exit 0
        }
    } catch {
        Write-Host "[!!] AppX re-registration failed: $_" -ForegroundColor Yellow
    }

    # Step 2: bootstrap via asheroto/winget-install from PSGallery
    Write-Host '[..] Bootstrapping winget via PSGallery (asheroto/winget-install)...' -ForegroundColor Yellow

    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Where-Object { $_.Version -ge '2.8.5.201' })) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }

    Install-Script -Name winget-install -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
    $installed = Get-InstalledScript 'winget-install' -ErrorAction SilentlyContinue
    if ($null -eq $installed) { throw 'winget-install script not found after PSGallery install.' }

    $scriptFile = Join-Path $installed.InstalledLocation 'winget-install.ps1'
    $ps = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
    $proc = Start-Process $ps -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptFile`" -Force" -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Warning "winget-install exited with code $($proc.ExitCode)."
    }

    Start-Sleep -Seconds 3
    if (Test-WingetWorking) {
        if (-not $Silent) {
            Write-Host '[OK] winget repaired successfully.' -ForegroundColor Green
            Read-Host 'Press Enter to exit'
        }
        exit 0
    }

    throw 'All repair attempts failed. winget is still not working.'
} catch {
    Write-Host "[!!] Failed to repair winget: $_" -ForegroundColor Red
    if (-not $Silent) { Read-Host 'Press Enter to exit' }
    exit 1
}
