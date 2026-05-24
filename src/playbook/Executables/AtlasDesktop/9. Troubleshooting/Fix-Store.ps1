#Requires -Version 5.1
# Repairs Microsoft Store and Xbox/Gaming Services install failures.
# Two root causes addressed:
#   1. StateRepository-Deployment.srd corruption — deleting it forces a clean rebuild on next AppX operation
#   2. Store-essential services Disabled by debloat tools — promoted to Manual so Windows can trigger-start them
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

# --- Admin elevation ---
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Silent) { $argList += ' -Silent' }
    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs -Wait
    } catch {
        Write-Host '[!!] Administrator privileges are required.' -ForegroundColor Red
        if (-not $Silent) { $null = Read-Host 'Press Enter to exit' }
        exit 1
    }
    exit 0
}

# --- Constants ---

# ClipSVC validates app licenses; AppXSvc deploys packages; StateRepository tracks the installed-app database
$storeServices   = @('ClipSVC', 'AppXSvc', 'StateRepository')
# Required for Xbox Game Pass and Gaming Services installs
$gamingServices  = @('GamingServices', 'GamingServicesNet', 'XboxNetApiSvc', 'XblAuthManager', 'XblGameSave')
$allRootServices = $storeServices + $gamingServices

# SQLite database tracking all installed AppX packages; corruption causes 0x80073CF9 and similar errors
$stateRepoFile = 'C:\ProgramData\Microsoft\Windows\AppRepository\StateRepository-Deployment.srd'

# --- Output helpers ---
function Write-FixStatus ([string]$Message) { Write-Host "[..] $Message" -ForegroundColor Yellow }
function Write-FixOK     ([string]$Message) { Write-Host "[OK] $Message" -ForegroundColor Green  }
function Write-FixWarn   ([string]$Message) { Write-Host "[??] $Message" -ForegroundColor Yellow }
function Write-FixError  ([string]$Message) { Write-Host "[!!] $Message" -ForegroundColor Red    }

# --- Service helpers ---

function Get-ServiceDependents ([string[]]$Names) {
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $Names) {
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($svc) {
            $svc.DependentServices | ForEach-Object { [void]$seen.Add($_.ServiceName) }
        }
    }
    return [string[]]$seen
}

function Stop-ServiceSafe ([string]$Name) {
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -ne 'Stopped') {
        Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
    }
}

function Start-ServiceSafe ([string]$Name) {
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -ne 'Running') {
        Start-Service -Name $Name -ErrorAction SilentlyContinue
    }
}

function Set-StartupTypeSafe ([string]$Name, [string]$StartupType) {
    Set-Service -Name $Name -StartupType $StartupType -ErrorAction SilentlyContinue
}

# --- Step 1: collect all services that depend on the root set (must be stopped before roots) ---
Write-FixStatus 'Collecting dependent services...'
$dependents = Get-ServiceDependents -Names $allRootServices
$stopOrder  = $dependents + $allRootServices
$startOrder = $storeServices + $gamingServices + $dependents

# --- Step 2: backup current startup types before touching anything ---
$backup = @{}
foreach ($name in ($allRootServices + $dependents)) {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if ($svc) { $backup[$name] = $svc.StartType.ToString() }
}

# --- Step 3: disable and stop all affected services ---
Write-FixStatus 'Stopping services...'
foreach ($name in $stopOrder) {
    Set-StartupTypeSafe -Name $name -StartupType 'Disabled'
    Stop-ServiceSafe -Name $name
}
Start-Sleep -Seconds 2

try {
    # --- Step 4: delete the corrupt AppX deployment state database ---
    # Windows automatically recreates StateRepository-Deployment.srd on the next package operation
    Write-FixStatus 'Deleting StateRepository-Deployment.srd...'
    if (Test-Path -LiteralPath $stateRepoFile) {
        Remove-Item -LiteralPath $stateRepoFile -Force
        Write-FixOK 'Deleted StateRepository-Deployment.srd.'
    } else {
        Write-FixWarn 'StateRepository-Deployment.srd not found — database may already be healthy.'
    }
} finally {
    # --- Step 5: restore startup types ---
    # Essential services that were Disabled (e.g. after debloat) get promoted to Manual.
    # Restoring Disabled means the fix only works until next reboot.
    Write-FixStatus 'Restoring service startup types...'
    foreach ($name in ($allRootServices + $dependents)) {
        $original = $backup[$name]
        if (-not $original) { continue }

        $isEssential = $allRootServices -contains $name
        $target = if ($isEssential -and $original -eq 'Disabled') { 'Manual' } else { $original }

        if ($target -ne $original) {
            Write-FixWarn "'$name' was Disabled — promoting to Manual so Store can trigger-start it."
        }
        Set-StartupTypeSafe -Name $name -StartupType $target
    }

    # --- Step 6: restart core services ---
    Write-FixStatus 'Starting services...'
    foreach ($name in $startOrder) {
        Start-ServiceSafe -Name $name
    }
    Start-Sleep -Seconds 1
}

# --- Step 7: Gaming Services package check ---
# If the package is missing entirely, the gaming service binaries don't exist and installs always fail
Write-FixStatus 'Checking Gaming Services package...'
$gsPkg = Get-AppxPackage -Name 'Microsoft.GamingServices' -ErrorAction SilentlyContinue
if (-not $gsPkg) {
    Write-FixWarn 'Microsoft.GamingServices package not found.'
    if (Get-Command -Name 'winget' -ErrorAction SilentlyContinue) {
        Write-FixStatus 'Reinstalling Gaming Services via winget...'
        & winget install --id 'Microsoft.GamingServices' --silent --accept-package-agreements --accept-source-agreements --force 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-FixOK 'Gaming Services reinstalled.'
        } else {
            Write-FixError "Gaming Services reinstall failed (winget exit $LASTEXITCODE). Install it manually from the Microsoft Store."
        }
    } else {
        Write-FixError 'winget unavailable. Install Gaming Services manually from the Microsoft Store.'
    }
} else {
    Write-FixOK "Gaming Services present (v$($gsPkg.Version))."
}

Write-Host ''
Write-FixOK 'Done. Restart recommended, then test the Store.'
if (-not $Silent) { $null = Read-Host 'Press Enter to exit' }
