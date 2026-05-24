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

# BFS through the full dependency chain — catches transitive dependents that a simple
# DependentServices query misses (e.g. a dependent of a dependent of ClipSVC)
function Get-ServiceDependentsBFS ([string[]]$Names) {
    $seen  = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $queue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($n in $Names) { [void]$queue.Enqueue($n) }

    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        $svc = Get-Service -Name $current -ErrorAction SilentlyContinue
        if (-not $svc) { continue }
        foreach ($dep in $svc.DependentServices) {
            if ($seen.Add($dep.ServiceName)) {
                [void]$queue.Enqueue($dep.ServiceName)
            }
        }
    }
    # Root services are tracked separately; remove them from the dependent set
    foreach ($n in $Names) { [void]$seen.Remove($n) }
    return [string[]]$seen
}

function Stop-ServiceSafe ([string]$Name) {
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc -or $svc.Status -eq 'Stopped') { return }
    Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
    # Wait up to 15 s for the service to reach Stopped before moving on
    try { $svc.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(15)) } catch { }
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

# --- Step 1: collect the full transitive dependent tree ---
Write-FixStatus 'Collecting dependent services (full tree)...'
$dependents = Get-ServiceDependentsBFS -Names $allRootServices
$stopOrder  = $dependents + $allRootServices          # dependents before roots
$startOrder = $storeServices + $gamingServices + $dependents  # roots before dependents

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
    # Restoring Disabled means the fix only works until the next reboot.
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

    # --- Step 6: restart StateRepository so AppX operations can proceed immediately ---
    Write-FixStatus 'Starting StateRepository...'
    Start-ServiceSafe -Name 'StateRepository'

    # Trigger-started services (ClipSVC, AppXSvc) are started by Windows on demand —
    # forcing them here is unnecessary and may fail if no AppX operation is in flight
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

# --- Step 8: reinstall the Store package ---
# wsreset.exe -i silently reinstalls the WindowsStore AppX package without opening the Store window.
# This repairs a missing or damaged Store installation — distinct from wsreset.exe (cache clear only).
Write-FixStatus 'Reinstalling Store package (wsreset -i)...'
$wsreset = Start-Process -FilePath 'wsreset.exe' -ArgumentList '-i' -Wait -PassThru
if ($wsreset.ExitCode -eq 0) {
    Write-FixOK 'Store package reinstalled.'
} else {
    Write-FixWarn "wsreset -i exited with code $($wsreset.ExitCode)."
}

Write-Host ''
Write-FixOK 'Done. Restart recommended, then test the Store.'
if (-not $Silent) { $null = Read-Host 'Press Enter to exit' }
