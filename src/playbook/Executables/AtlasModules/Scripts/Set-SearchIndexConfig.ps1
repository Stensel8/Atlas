#Requires -Version 5.1
[CmdletBinding(DefaultParameterSetName = 'Help')]
param (
    [Parameter(ParameterSetName = 'Include', Mandatory)][switch]$Include,
    [Parameter(ParameterSetName = 'Exclude', Mandatory)][switch]$Exclude,
    [Parameter(ParameterSetName = 'Include', Mandatory)]
    [Parameter(ParameterSetName = 'Exclude', Mandatory)]
    [string]$Path,
    [Parameter(ParameterSetName = 'CleanPolicies', Mandatory)][switch]$CleanPolicies,
    [Parameter(ParameterSetName = 'Start', Mandatory)][switch]$Start,
    [Parameter(ParameterSetName = 'Stop', Mandatory)][switch]$Stop
)

$ErrorActionPreference = 'Stop'

$settingsPages = Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Helpers\SettingsPages.ps1'
$serviceKey    = 'HKLM:\SYSTEM\CurrentControlSet\Services\WSearch'

if ($Stop) {
    Write-Output 'Stopping the indexer...'
    if (Test-Path -LiteralPath $settingsPages -PathType Leaf) {
        & $settingsPages -Operation hide -Page 'cortana-windowssearch' -Silent
    }
    Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle -like '*Indexing Options*' -or $_.CommandLine -match 'srchadmin\.dll' } |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -LiteralPath $serviceKey -Name 'Start' -Value 4 -Type DWord -ErrorAction SilentlyContinue
    Stop-Service -Name 'WSearch' -Force -ErrorAction SilentlyContinue
    return
}

if ($Start) {
    Write-Output 'Starting the indexer...'
    Set-ItemProperty -LiteralPath $serviceKey -Name 'Start'            -Value 2 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -LiteralPath $serviceKey -Name 'DelayedAutostart' -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Start-Service -Name 'WSearch' -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $settingsPages -PathType Leaf) {
        & $settingsPages -Operation unhide -Page 'cortana-windowssearch' -Silent
    }
    Write-Output 'Updating policy... (this might take a moment)'
    & gpupdate.exe /force /wait:0 2>&1 | Out-Null
    return
}

if ($CleanPolicies) {
    Write-Output 'Cleaning policies...'
    foreach ($key in @(
        'HKLM:\Software\Policies\Microsoft\Windows\Windows Search\DefaultExcludedPaths'
        'HKLM:\Software\Policies\Microsoft\Windows\Windows Search\DefaultIndexedPaths'
        'HKLM:\Software\Microsoft\Windows Search\CurrentPolicies\DefaultExcludedPaths'
        'HKLM:\Software\Microsoft\Windows Search\CurrentPolicies\DefaultIndexedPaths'
        'HKLM:\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Paths'
        'HKLM:\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Exclusions'
    )) {
        Remove-Item -LiteralPath $key -Recurse -Force -ErrorAction SilentlyContinue
        # Sites\LocalHost subtree has restricted ACLs, creation may be denied even as admin.
        # Skipping silently is safe: absence of the key means the indexer uses its default.
        New-Item -Path $key -Force -ErrorAction SilentlyContinue | Out-Null
    }
    return
}

if ($Include -or $Exclude) {
    $root = if ($Include) {
        'HKLM:\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Paths'
    } else {
        'HKLM:\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Exclusions'
    }

    Write-Output 'Configuring indexer path...'
    $i = 0
    while ($true) {
        $subKey = Join-Path -Path $root -ChildPath "$i"
        if (-not (Test-Path -LiteralPath $subKey)) { break }
        $existing = (Get-ItemProperty -LiteralPath $subKey -Name 'Path' -ErrorAction SilentlyContinue).Path
        if ($existing -ieq $Path) {
            Write-Output 'Path already exists in the index, skipping...'
            return
        }
        $i++
    }
    # Sites\LocalHost subtree has restricted ACLs; creating subkeys may be denied even as admin.
    # Skipping silently is safe: the indexer falls back to its compiled-in defaults.
    $subKeyPath = Join-Path -Path $root -ChildPath "$i"
    try {
        New-Item -Path $subKeyPath -Force -ErrorAction Stop | Out-Null
        Set-ItemProperty -LiteralPath $subKeyPath -Name 'Path' -Value $Path -Type String
    } catch {
        Write-Warning "Could not write index path '$Path': $_"
    }
    return
}

Write-Host 'Usage: indexConf.ps1 -Include|-Exclude -Path <path> | -CleanPolicies | -Start | -Stop' -ForegroundColor Yellow
