#Requires -Version 5.1

<#
    .SYNOPSIS
    Uninstalls or reinstalls Microsoft Edge and its related components. Made by @he3als.

    .Description
    Uninstalls or reinstalls Microsoft Edge and its related components in a non-forceful manner, based upon switches or user choices in a TUI.

    .PARAMETER UninstallEdge
    Uninstalls Edge, leaving the Edge user data.

    .PARAMETER InstallEdge
    Installs Edge, leaving the previous Edge user data.

    .PARAMETER InstallWebView
    Installs Edge WebView2 using the Evergreen installer.

    .PARAMETER RemoveEdgeData
    Removes all Edge user data. Compatible with -InstallEdge.

    .PARAMETER KeepAppX
    Doesn't check for and remove the AppX, in case you want to use alternative AppX removal methods. Doesn't work with UninstallEdge.

    .PARAMETER NonInteractive
    When combined with other parameters, this does not prompt the user for anything.

    .LINK
    https://github.com/he3als/EdgeRemover
#>

param (
    [switch]$UninstallEdge,
    [switch]$InstallEdge,
    [switch]$InstallWebView,
    [switch]$RemoveEdgeData,
    [switch]$KeepAppX,
    [switch]$NonInteractive
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$version = '1.9.5'

$ProgressPreference = 'SilentlyContinue'
$sys32 = [Environment]::GetFolderPath('System')
$windir = [Environment]::GetFolderPath('Windows')
$env:path = "$windir;$sys32;$sys32\Wbem;$sys32\WindowsPowerShell\v1.0;" + $env:path
$msedgeExePaths = @(
    "$([Environment]::GetFolderPath('ProgramFilesx86'))\Microsoft\Edge\Application\msedge.exe",
    "$([Environment]::GetFolderPath('ProgramFiles'))\Microsoft\Edge\Application\msedge.exe"
)

if ($NonInteractive -and (!$UninstallEdge -and !$InstallEdge -and !$InstallWebView)) {
    $NonInteractive = $false
}
if ($InstallEdge -and $UninstallEdge) {
    throw "You can't use both -InstallEdge and -UninstallEdge as arguments."
}

function Wait-UserInput ($message = 'Press Enter to exit') {
    if (!$NonInteractive) { $null = Read-Host $message }
}

enum LogLevel {
    Success
    Info
    Warning
    Error
    Critical
}
function Write-Status {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Text,
        [LogLevel]$Level = 'Info',
        [switch]$Exit,
        [string]$ExitString = 'Press Enter to exit',
        [int]$ExitCode = 1
    )

    $colour = @(
        'Green',
        'White',
        'Yellow',
        'Red',
        'Red'
    )[$([LogLevel].GetEnumValues().IndexOf($Level))]

    $Text -split "`n" | ForEach-Object {
        Write-Host "[$($Level.ToString().ToUpper())] $_" -ForegroundColor $colour
    }

    if ($Exit) {
        Write-Output ''
        Wait-UserInput $ExitString
        exit $ExitCode
    }
}

function Test-InternetConnectivity {
    try {
        Invoke-WebRequest -Uri 'https://www.microsoft.com/robots.txt' -Method GET -TimeoutSec 10 -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Status "Failed to reach Microsoft.com via web request. You must have an internet connection to reinstall Edge and its components.`n$($_.Exception.Message)" -Level Critical -Exit -ExitCode 404
    }
}

function Remove-ItemIfExists($Path) {
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Force -Recurse -Confirm:$false
    }
}

# True if it's installed
function Test-EdgeInstalled {
    foreach ($msedgeExe in $msedgeExePaths) {
        if (Test-Path $msedgeExe) {
            return $true
        }
    }

    return $false
}

function Stop-EdgeProcesses {
    $ErrorActionPreference = 'SilentlyContinue'
    foreach ($service in (Get-Service -Name '*edge*' | Where-Object { $_.DisplayName -like '*Microsoft Edge*' }).Name) {
        Stop-Service -Name $service -Force
    }
    foreach (
        $process in
        (Get-Process | Where-Object { ($_.Path -like "$([Environment]::GetFolderPath('ProgramFilesX86'))\Microsoft\*") -or ($_.Name -like '*msedge*') }).Id
    ) {
        Stop-Process -Id $process -Force
    }
    $ErrorActionPreference = 'Continue'
}

function Disable-EdgeUpdateInfrastructure {
    $serviceNames = @(
        'edgeupdate',
        'edgeupdatem',
        'MicrosoftEdgeUpdate',
        'MicrosoftEdgeElevationService'
    )

    try {
        $serviceNames += Get-CimInstance Win32_Service -ErrorAction Stop |
        Where-Object {
            ($_.Name -like '*edge*' -and $_.DisplayName -like '*Microsoft Edge*') -or
            ($_.PathName -like '*\Microsoft\EdgeUpdate\*') -or
            ($_.PathName -like '*\Microsoft\Edge\Application\*')
        } |
        Select-Object -ExpandProperty Name
    }
    catch {
        Write-Status "Failed to discover Edge services: $($_.Exception.Message)" -Level Warning
    }

    foreach ($serviceName in @($serviceNames | Where-Object { $_ } | Sort-Object -Unique)) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($null -eq $service) {
            continue
        }

        try {
            if ($service.Status -ne 'Stopped') {
                Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            }
            Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop
        }
        catch {
            Write-Status "Failed to disable Edge update service '$serviceName': $($_.Exception.Message)" -Level Warning
        }
    }

    foreach ($taskName in @(
            'MicrosoftEdgeUpdateTaskMachineCore',
            'MicrosoftEdgeUpdateTaskMachineUA'
        )) {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) {
            Unregister-ScheduledTask -InputObject $task -Confirm:$false
        }
    }
}

function Install-EdgeChromium {
    Test-InternetConnectivity

    $temp = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) (New-Guid))
    $msi = "$temp\edge.msi"
    $msiLog = "$temp\edgeMsi.log"
    $link = 'Undefined'

    if ([Environment]::Is64BitOperatingSystem) {
        $arm = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
        $archString = ('x64', 'arm64')[$arm]
    }
    else {
        $archString = 'x86'
    }

    Write-Status 'Requesting from the Microsoft Edge Update API...'
    try {
        try {
            $edgeUpdateApi = (Invoke-WebRequest 'https://edgeupdates.microsoft.com/api/products' -UseBasicParsing).Content | ConvertFrom-Json
        }
        catch {
            Write-Status "Failed to request from EdgeUpdate API!
Error: $_" -Level Critical -Exit -ExitCode 4
        }

        $edgeItem = ($edgeUpdateApi | Where-Object { $_.Product -eq 'Stable' }).Releases |
        Where-Object { $_.Platform -eq 'Windows' -and $_.Architecture -eq $archString } |
        Where-Object { $_.Artifacts.Count -ne 0 } | Select-Object -First 1

        if ($null -eq $edgeItem) {
            Write-Status 'Failed to parse EdgeUpdate API! No matching artifacts found.' -Level Critical -Exit
        }

        $hashAlg = $edgeItem.Artifacts.HashAlgorithm | ForEach-Object { if ([string]::IsNullOrEmpty($_)) { 'SHA256' } else { $_ } }
        foreach ($var in @{
                link     = $edgeItem.Artifacts.Location
                hash     = $edgeItem.Artifacts.Hash
                version  = $edgeItem.ProductVersion
                sizeInMb = [math]::round($edgeItem.Artifacts.SizeInBytes / 1Mb)
                released = Get-Date $edgeItem.PublishedTime
            }.GetEnumerator()) {
            $val = $var.Value | Select-Object -First 1
            if ($val.Length -le 0) {
                Set-Variable -Name $var.Key -Value 'Undefined'
                if ($var.Key -eq 'link') { throw 'Failed to parse download link!' }
            }
            else {
                Set-Variable -Name $var.Key -Value $val
            }
        }
    }
    catch {
        Write-Status "Failed to parse Microsoft Edge from `"$link`"!
Error: $_" -Level Critical -Exit -ExitCode 5
    }
    Write-Status 'Parsed Microsoft Edge Update API!' -Level Success

    Write-Host "`nDownloading Microsoft Edge:" -ForegroundColor Cyan
    @(
        @('Released on: ', $released),
        @('Version: ', "$version (Stable)"),
        @('Size: ', "$sizeInMb Mb")
    ) | Foreach-Object {
        Write-Host ' - ' -NoNewline -ForegroundColor Magenta
        Write-Host $_[0] -NoNewline -ForegroundColor Yellow
        Write-Host $_[1]
    }

    Write-Output ''
    try {
        if ($null -eq (Get-Command curl.exe -EA 0)) {
            Write-Status "Couldn't find cURL, using Invoke-WebRequest, which is slower..." -Level Warning
            Invoke-WebRequest -Uri $link -Output $msi -UseBasicParsing
        }
        else {
            curl.exe -#L "$link" -o "$msi"
        }
    }
    catch {
        Write-Status "Failed to download Microsoft Edge from `"$link`"!
Error: $_" -Level Critical -Exit -ExitCode 6
    }
    Write-Output ''

    if ($hash -eq 'Undefined') {
        Write-Status "Not verifying hash as it's undefined, download might have failed." -Level Warning
    }
    else {
        Write-Status 'Verifying download by checking its hash...'
        if ((Get-FileHash -LiteralPath $msi -Algorithm $hashAlg).Hash -eq $hash) {
            Write-Status 'Verified the Microsoft Edge installer!' -Level Success
        }
        else {
            Write-Status 'Edge installer hash does not match. Refusing to continue with an untrusted installer.' -Level Critical -Exit -ExitCode 10
        }
    }

    Write-Status 'Installing Microsoft Edge...'
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$msi`" /l `"$msiLog`" /quiet" -Wait

    Write-Status 'Repairing Microsoft Edge...'
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/fa `"$msi`" /l `"$msiLog`" /quiet" -Wait

    if (!(Test-Path $msiLog)) {
        Write-Status "Couldn't find installer log at `"$msiLog`"! This likely means it failed." -Level Critical -Exit -ExitCode 7
    }

    Write-Status -Text "Installer log path: `"$msiLog`""
    if ($null -eq ($(Get-Content $msiLog) -like '*Product: Microsoft Edge -- * completed successfully.*')) {
        Write-Status "Can't find success string from Edge install log - it seems like the install was a failure." -Level Error -Exit -ExitCode 8
    }

    Write-Status -Text 'Installed Microsoft Edge!' -Level Success
}

function Install-WebView {
    Test-InternetConnectivity

    $dlPath = "$((Join-Path $([System.IO.Path]::GetTempPath()) $(New-Guid)))-webview2.exe"
    $link = 'https://go.microsoft.com/fwlink/p/?LinkId=2124703'

    Write-Status 'Downloading Edge WebView...'
    try {
        if ($null -eq (Get-Command curl.exe -EA 0)) {
            Write-Status "Couldn't find cURL, using Invoke-WebRequest, which is slower..." -Level Warning
            Invoke-WebRequest -Uri $link -Output $dlPath -UseBasicParsing
        }
        else {
            curl.exe -Ls "$link" -o "$dlPath"
        }
    }
    catch {
        Write-Status "Failed to download Edge WebView from `"$link`"!
Error: $_" -Level Critical -Exit -ExitCode 9
    }

    Write-Status 'Installing Edge WebView...'
    Start-Process -FilePath "$dlPath" -ArgumentList '/silent /install' -Wait

    Write-Status 'Installed Edge WebView!' -Level Success
}

# SYSTEM check - using SYSTEM previously caused issues
if ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -eq 'S-1-5-18') {
    Write-Status "This script can't be ran as TrustedInstaller/SYSTEM.
Please relaunch this script under a regular admin account." -Level Critical -Exit
}
else {
    if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        if ($PSBoundParameters.Count -le 0 -and !$args) {
            Start-Process cmd "/c PowerShell -NoP -EP RemoteSigned -File `"$PSCommandPath`"" -Verb RunAs
            exit
        }
        else {
            throw 'This script must be run as an administrator.'
        }
    }
}

$edgeInstalled = Test-EdgeInstalled
if (!$UninstallEdge -and !$InstallEdge -and !$InstallWebView) {
    $host.UI.RawUI.WindowTitle = "AtlasOS EdgeRemover"

    $continue = $false
    $RemoveEdgeData = $false
    while (!$continue) {
        Clear-Host
        $description = "This script removes or installs Microsoft Edge."
        Write-Host "$description`n" -ForegroundColor Blue
        Write-Host @"
To select an option, type its number.
To perform an action, also type its number.
"@ -ForegroundColor Yellow

        Write-Host "`nEdge is currently detected as: " -NoNewline -ForegroundColor Green
        Write-Host "$(@("Uninstalled", "Installed")[$edgeInstalled])" -ForegroundColor Cyan

        Write-Host "`n$("-" * $description.Length)" -ForegroundColor Magenta

        Write-Host "`nActions:"
        Write-Host @"
[1] Uninstall Edge
[2] Install Edge
[3] Install WebView
[4] Install both Edge & WebView
"@ -ForegroundColor Cyan

        $userInput = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

        switch ($userInput.VirtualKeyCode) {
            49 {
                # uninstall Edge (1)
                $UninstallEdge = $true
                $continue = $true
            }
            50 {
                # reinstall Edge (2)
                $InstallEdge = $true
                $continue = $true
            }
            51 {
                # reinstall WebView (3)
                $InstallWebView = $true
                $continue = $true
            }
            52 {
                # reinstall both (4)
                $InstallWebView = $true
                $InstallEdge = $true
                $continue = $true
            }
        }
    }

    Clear-Host
}

if ($UninstallEdge) {
    Write-Status 'Uninstalling Edge Chromium...'
    Stop-EdgeProcesses
    Disable-EdgeUpdateInfrastructure

    $setupCandidates = @()
    foreach ($root in @(
            "$([Environment]::GetFolderPath('ProgramFilesx86'))\Microsoft\Edge\Application",
            "$([Environment]::GetFolderPath('ProgramFiles'))\Microsoft\Edge\Application"
        )) {
        if (Test-Path $root) {
            $setupCandidates += Get-ChildItem -Path $root -Filter 'setup.exe' -Recurse -ErrorAction SilentlyContinue
        }
    }

    $setupCandidates = @($setupCandidates | Sort-Object -Property FullName -Unique)
    if ($setupCandidates.Count -gt 0) {
        foreach ($setup in $setupCandidates) {
            Write-Status "Running uninstaller at '$($setup.FullName)'..."
            $process = Start-Process -FilePath $setup.FullName -ArgumentList '--uninstall --msedge --system-level --verbose-logging --force-uninstall' -WindowStyle Hidden -Wait -PassThru
            if (($process.ExitCode -eq 0) -or (-not (Test-EdgeInstalled))) {
                break
            }

            Write-Status "Edge uninstaller exited with code $($process.ExitCode); trying fallback methods." -Level Info
        }
    }
    elseif (Test-EdgeInstalled) {
        Write-Status 'Could not locate a local Edge installer to perform uninstallation.' -Level Warning
    }

    Stop-EdgeProcesses
    if (Test-EdgeInstalled) {
        $legacyRemoved = $false
        try {
            Write-Status 'Trying PowerShell-based Edge removal fallback...'

            # Attempt winget uninstall first (cleanest path)
            if ($null -ne (Get-Command winget -ErrorAction SilentlyContinue)) {
                & winget uninstall --id Microsoft.Edge --silent --accept-source-agreements --disable-interactivity 2>&1 | Out-Null
                Stop-EdgeProcesses
            }

            if (-not (Test-EdgeInstalled)) {
                $legacyRemoved = $true
            }
            else {
                # Force-remove Edge installation directories via takeown + icacls
                foreach ($edgeRoot in @(
                    "$([Environment]::GetFolderPath('ProgramFilesx86'))\Microsoft\Edge",
                    "$([Environment]::GetFolderPath('ProgramFiles'))\Microsoft\Edge",
                    "$([Environment]::GetFolderPath('ProgramFilesx86'))\Microsoft\EdgeUpdate",
                    "$([Environment]::GetFolderPath('ProgramFiles'))\Microsoft\EdgeUpdate"
                )) {
                    if (Test-Path $edgeRoot) {
                        & takeown.exe /f "$edgeRoot" /r /d Y 2>&1 | Out-Null
                        & icacls.exe "$edgeRoot" /grant 'Administrators:F' /t /c /q 2>&1 | Out-Null
                        Remove-Item -Path $edgeRoot -Force -Recurse -ErrorAction SilentlyContinue
                    }
                }

                # Remove Edge registry artifacts
                foreach ($regPath in @(
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge',
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge',
                    'HKLM:\SOFTWARE\Microsoft\EdgeUpdate',
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate'
                )) {
                    Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
                }

                Stop-EdgeProcesses
                $legacyRemoved = -not (Test-EdgeInstalled)
            }
        }
        catch {
            if (Test-EdgeInstalled) {
                Write-Status "PowerShell Edge removal fallback failed: $($_.Exception.Message)" -Level Warning
            }
        }

        if ((-not $legacyRemoved) -and (Test-EdgeInstalled)) {
            if ($KeepAppX -or $NonInteractive) {
                Write-Status 'Edge binaries were not fully removed. Continuing so playbook cleanup can finish.' -Level Warning
            }
            else {
                Write-Status 'Failed to uninstall Microsoft Edge using all available removal methods.' -Level Critical -Exit -ExitCode 12
            }
        }
        else {
            Write-Status 'Successfully removed Microsoft Edge.' -Level Success
        }
    }
    else {
        Write-Status 'Edge is already uninstalled.' -Level Success
    }

    # Remove stale Edge shortcuts from common Start Menu and public Desktop
    foreach ($dir in @(
        [Environment]::GetFolderPath('CommonPrograms'),
        [Environment]::GetFolderPath('CommonDesktopDirectory')
    )) {
        if (-not (Test-Path $dir)) { continue }
        Get-ChildItem -Path $dir -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.BaseName -match '\bEdge\b' } |
            ForEach-Object {
                Write-Status "Removing Edge shortcut: $($_.Name)" -Level Info
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            }
    }

    Write-Output ""
}

if ($RemoveEdgeData) {
    Stop-EdgeProcesses
    Remove-ItemIfExists "$([Environment]::GetFolderPath('LocalApplicationData'))\Microsoft\Edge"
    Write-Status 'Removed any existing Edge Chromium user data.'
    Write-Output ''
}

if ($InstallEdge) {
    Install-EdgeChromium
    Write-Output ''
}
if ($InstallWebView) {
    Install-WebView
    Write-Output ''
}

Write-Host 'Completed.' -ForegroundColor Cyan
if ($NonInteractive) { exit }
Wait-UserInput
