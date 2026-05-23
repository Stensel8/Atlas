#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
param(
    [switch]$Silent,
    [switch]$NoDashes
)

$dashes = '-' * 101

if (-not $Silent -and -not $NoDashes) { Write-Output $dashes }

$connected = try {
    $ping = [System.Net.NetworkInformation.Ping]::new()
    ($ping.Send('www.microsoft.com', 2000)).Status -eq [System.Net.NetworkInformation.IPStatus]::Success
} catch { $false }

if (-not $connected) {
    if ($Silent) { exit 2 }
    Write-Output 'You must have an internet connection to continue.'
    Write-Output 'Press any key to exit...'
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 2
}

if (-not $Silent) { Write-Output 'Checking for WinGet...' }

$wingetPresent = [bool](Get-Command winget -ErrorAction SilentlyContinue)
$wingetOk = $false
if ($wingetPresent) {
    & winget search 'Microsoft Visual Studio Code' --accept-source-agreements 2>&1 | Out-Null
    $wingetOk = ($LASTEXITCODE -eq 0)
}

if (-not $wingetOk) {
    if ($Silent) { exit 1 }
    $action = if ($wingetPresent) { 'update' } else { 'install' }
    $uri    = if ($action -eq 'install') { 'ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1' } else { 'ms-windows-store://downloadsandupdates' }
    Write-Output ''
    Write-Output "You need the latest version of WinGet to use this script."
    Write-Output "WinGet is included with 'App Installer' on the Microsoft Store, it's also on GitHub."
    $choice = Read-Host "Would you like to open the Microsoft Store to $action it? [Y/N]"
    if ($choice -match '^[Yy]$') { Start-Process $uri }
    exit 2
}

if (-not $Silent -and -not $NoDashes) { Write-Output $dashes }
exit 0
