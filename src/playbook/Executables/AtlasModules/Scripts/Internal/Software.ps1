#Requires -Version 5.1
param (
    [switch]$Chrome,
    [switch]$Brave,
    [switch]$Firefox,
    [switch]$Toolbox
)

$ErrorActionPreference = 'Stop'

$executablesRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$initScript = Join-Path -Path $executablesRoot -ChildPath 'AtlasModules\initPowerShell.ps1'
if (-not (Test-Path -LiteralPath $initScript -PathType Leaf)) {
    throw "Atlas PowerShell initialization script '$initScript' is missing."
}

. $initScript

$script:IsArm64 = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
$script:TempDir = Join-Path -Path $env:TEMP -ChildPath ([guid]::NewGuid().ToString())

function Remove-AtlasTempDirectory {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir -PathType Container)) {
        Remove-Item -LiteralPath $script:TempDir -Force -Recurse -ErrorAction SilentlyContinue
    }
}

# Used only for components not available on winget (DirectX, Atlas Toolbox)
function Invoke-AtlasDownload {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$Description
    )
    Write-Output "Downloading $Description..."
    & curl.exe -LSs $Uri -o $Destination --connect-timeout 10 --retry 3 --retry-all-errors
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        throw "Downloading $Description from '$Uri' failed with exit code $LASTEXITCODE."
    }
}

function Start-AtlasInstaller {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$ArgumentList,
        [Parameter(Mandatory)][string]$Description,
        [int[]]$SuccessExitCode = @(0)
    )
    Write-Output "Installing $Description..."
    $process = Start-Process -FilePath $FilePath -WindowStyle Hidden -ArgumentList $ArgumentList -Wait -PassThru
    if ($process.ExitCode -notin $SuccessExitCode) {
        throw "Installing $Description failed with exit code $($process.ExitCode)."
    }
}

# ── Connectivity & winget readiness ─────────────────────────────────────────

function Test-AtlasInternetConnectivity {
    try {
        $ping = [System.Net.NetworkInformation.Ping]::new()
        return ($ping.Send('8.8.8.8', 2000)).Status -eq [System.Net.NetworkInformation.IPStatus]::Success
    } catch {
        return $false
    }
}

function Assert-AtlasWingetReady {
    # Ensure NuGet provider is available (needed for Install-Script)
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Where-Object { $_.Version -ge '2.8.5.201' })) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }

    # Use asheroto/winget-install to bootstrap/repair winget if needed
    # Credits: https://github.com/asheroto/winget-install
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Output 'winget not found — bootstrapping via asheroto/winget-install...'
        try {
            Install-Script -Name winget-install -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
            $installed = Get-InstalledScript 'winget-install' -ErrorAction SilentlyContinue
            if ($installed) {
                $scriptFile = Join-Path $installed.InstalledLocation 'winget-install.ps1'
                $ps = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
                $proc = Start-Process $ps `
                    -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptFile`" -Force" `
                    -Wait -PassThru
                if ($proc.ExitCode -ne 0) {
                    Write-Warning "winget-install exited with code $($proc.ExitCode)."
                }
            }
        } catch {
            Write-Warning "winget bootstrap failed: $($_.Exception.Message)"
        }
    }

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget is not available and could not be bootstrapped.'
    }

    # Refresh sources quietly
    & winget source update --disable-interactivity 2>&1 | Out-Null
    Write-Output 'winget is ready.'
}

# ── winget install helper ────────────────────────────────────────────────────

function Invoke-WingetInstall {
    param(
        [Parameter(Mandatory)][string]$Id,
        [string]$Description = $Id
    )
    Write-Output "Installing $Description..."
    & winget install --id $Id --silent --accept-package-agreements --accept-source-agreements --no-upgrade 2>&1 | Out-Null
    # Treat "already installed" / "no upgrade" exit codes as success
    if ($LASTEXITCODE -notin @(0, -1978335189, -1978335147, -1978335212)) {
        Write-Warning "$Description (winget id: $Id) returned exit code $LASTEXITCODE."
    }
}

# ── Software installers ──────────────────────────────────────────────────────

function Install-VisualCppRuntimes {
    $vcRedists = @(
        @('Microsoft.VCRedist.2005.x86',  '2005 x86'),
        @('Microsoft.VCRedist.2005.x64',  '2005 x64'),
        @('Microsoft.VCRedist.2008.x86',  '2008 x86'),
        @('Microsoft.VCRedist.2008.x64',  '2008 x64'),
        @('Microsoft.VCRedist.2010.x86',  '2010 x86'),
        @('Microsoft.VCRedist.2010.x64',  '2010 x64'),
        @('Microsoft.VCRedist.2012.x86',  '2012 x86'),
        @('Microsoft.VCRedist.2012.x64',  '2012 x64'),
        @('Microsoft.VCRedist.2013.x86',  '2013 x86'),
        @('Microsoft.VCRedist.2013.x64',  '2013 x64'),
        @('Microsoft.VCRedist.2015+.x86', '2015+ x86'),
        @('Microsoft.VCRedist.2015+.x64', '2015+ x64')
    )
    foreach ($vc in $vcRedists) {
        Invoke-WingetInstall -Id $vc[0] -Description "Visual C++ Runtime $($vc[1])"
    }
}

function Install-ArchiveTool {
    $nanaZipInstalled = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like '*NanaZip*' }
    if ($nanaZipInstalled) {
        Write-Output 'NanaZip is already installed, skipping.'
        return
    }

    Invoke-WingetInstall -Id 'M2Team.NanaZip' -Description 'NanaZip'
    if ($LASTEXITCODE -notin @(0, -1978335189, -1978335147, -1978335212)) {
        Write-Warning 'NanaZip via winget failed; falling back to 7-Zip.'
        Invoke-WingetInstall -Id '7zip.7zip' -Description '7-Zip'
    }
}

function Install-DirectXRuntime {
    # Legacy DirectX is not available on winget — direct download required
    $installerPath = Join-Path -Path $script:TempDir -ChildPath 'directx.exe'
    $extractPath   = Join-Path -Path $script:TempDir -ChildPath 'directx'
    Invoke-AtlasDownload -Uri 'https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe' -Destination $installerPath -Description 'legacy DirectX runtimes'
    Start-AtlasInstaller -FilePath $installerPath -ArgumentList ('/q /c /t:"' + $extractPath + '"') -Description 'legacy DirectX runtime extractor'
    Start-AtlasInstaller -FilePath (Join-Path -Path $extractPath -ChildPath 'dxsetup.exe') -ArgumentList '/silent' -Description 'legacy DirectX runtimes'
}

function Install-AtlasToolbox {
    # Atlas Toolbox is not yet on winget — direct download from GitHub
    if ($env:PATH -like '*Atlas Toolbox*') { return }
    $toolboxPath = Join-Path -Path $script:TempDir -ChildPath 'toolbox.exe'
    Invoke-AtlasDownload -Uri 'https://github.com/Atlas-OS/atlas-toolbox/releases/latest/download/AtlasToolbox-Setup.exe' -Destination $toolboxPath -Description 'Atlas Toolbox'
    Start-AtlasInstaller -FilePath $toolboxPath -ArgumentList '/verysilent /install /MERGETASKS="desktopicon"' -Description 'Atlas Toolbox'
}

function Install-BraveBrowser  { Invoke-WingetInstall -Id 'Brave.Brave'       -Description 'Brave Browser'    }
function Install-FirefoxBrowser { Invoke-WingetInstall -Id 'Mozilla.Firefox'   -Description 'Mozilla Firefox'  }
function Install-ChromeBrowser  { Invoke-WingetInstall -Id 'Google.Chrome'     -Description 'Google Chrome'    }

# ── Entry point ──────────────────────────────────────────────────────────────

New-Item -ItemType Directory -Path $script:TempDir -Force | Out-Null
try {
    if ($Toolbox)  { Install-AtlasToolbox;    return }
    if ($Brave)    { Install-BraveBrowser;    return }
    if ($Firefox)  { Install-FirefoxBrowser;  return }
    if ($Chrome)   { Install-ChromeBrowser;   return }

    # Default: base software (VC++, archive tool, DirectX)
    if (-not (Test-AtlasInternetConnectivity)) {
        Write-Warning 'No internet connection detected. Skipping base software installation (VC++ runtimes, NanaZip, DirectX). These can be installed manually from the Atlas Toolbox once online.'
        exit 0
    }

    Assert-AtlasWingetReady
    Install-VisualCppRuntimes
    Install-ArchiveTool
    Install-DirectXRuntime
}
finally {
    Remove-AtlasTempDirectory
}
