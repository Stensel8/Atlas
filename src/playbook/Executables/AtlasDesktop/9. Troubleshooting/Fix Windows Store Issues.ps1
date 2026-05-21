#Requires -Version 5.1
# Fixes Windows Store app install failures by rebuilding the App Repository state.
# Equivalent to TheyCreeper/StoreFixer — stops ClipSVC/AppXSvc/StateRepository,
# deletes StateRepository-Deployment.srd, and restores services.
# Requires Administrator privileges.

param([switch]$Silent)

$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs -Wait
    } catch {
        Write-Host '[!!] Administrator privileges are required.' -ForegroundColor Red
        if (-not $Silent) { Read-Host 'Press Enter to exit' }
        exit 1
    }
    exit 0
}

$targetFile = 'C:\ProgramData\Microsoft\Windows\AppRepository\StateRepository-Deployment.srd'
$rootServices = @('ClipSVC', 'AppXSvc', 'StateRepository')

function Get-DependentServiceNames([string[]]$serviceNames) {
    $deps = @()
    foreach ($name in $serviceNames) {
        try {
            $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
            if ($svc) {
                $svc.DependentServices | ForEach-Object { $deps += $_.ServiceName }
            }
        } catch {}
    }
    return $deps | Sort-Object -Unique
}

function Set-ServiceStartSafe([string]$name, [string]$startType) {
    try {
        Set-Service -Name $name -StartupType $startType -ErrorAction SilentlyContinue
    } catch {}
}

function Stop-ServiceSafe([string]$name) {
    try {
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -ne 'Stopped') {
            Stop-Service -Name $name -Force -ErrorAction SilentlyContinue
        }
    } catch {}
}

function Start-ServiceSafe([string]$name) {
    try {
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -ne 'Running') {
            Start-Service -Name $name -ErrorAction SilentlyContinue
        }
    } catch {}
}

Write-Host '[..] Collecting dependent services...' -ForegroundColor Yellow
$dependents = Get-DependentServiceNames $rootServices
$allServices = ($rootServices + $dependents) | Sort-Object -Unique

# Backup startup types
$backup = @{}
foreach ($name in $allServices) {
    try {
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($svc) { $backup[$name] = $svc.StartType }
    } catch {}
}
Write-Host "[OK] Backed up startup types for $($backup.Count) services." -ForegroundColor Green

try {
    # Disable and stop dependents first, then roots
    Write-Host '[..] Disabling and stopping services...' -ForegroundColor Yellow
    foreach ($name in ($dependents + $rootServices)) {
        Set-ServiceStartSafe $name 'Disabled'
        Stop-ServiceSafe $name
    }
    Start-Sleep -Seconds 2

    # Delete the corrupt state repository file
    Write-Host '[..] Deleting StateRepository-Deployment.srd...' -ForegroundColor Yellow
    if (Test-Path $targetFile) {
        Remove-Item -LiteralPath $targetFile -Force
        Write-Host '[OK] File deleted.' -ForegroundColor Green
    } else {
        Write-Host '[??] File not found — may already be clean.' -ForegroundColor Yellow
    }
} finally {
    # Always restore services
    Write-Host '[..] Restoring service startup types...' -ForegroundColor Yellow
    foreach ($name in $allServices) {
        if ($backup.ContainsKey($name)) {
            Set-ServiceStartSafe $name $backup[$name].ToString()
        }
    }

    Write-Host '[..] Starting services...' -ForegroundColor Yellow
    foreach ($name in ($rootServices + $dependents)) {
        Start-ServiceSafe $name
    }
    Start-Sleep -Seconds 1
}

Write-Host "`n[OK] Done. Restart recommended, then test the Windows Store." -ForegroundColor Green
if (-not $Silent) { Read-Host 'Press Enter to exit' }
