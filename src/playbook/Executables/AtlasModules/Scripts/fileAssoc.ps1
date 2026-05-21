#Requires -Version 5.1
param([string]$Browser)

$ErrorActionPreference = 'Stop'

$assocScript = Join-Path $PSScriptRoot 'ASSOC.ps1'
if (-not (Test-Path -LiteralPath $assocScript)) {
    throw "ASSOC.ps1 not found: $assocScript"
}

$baseAssociations = @('.url:InternetShortcut')

$browserMap = @{
    'Brave'         = @(
        'Proto:https:BraveHTML', 'Proto:http:BraveHTML',
        '.htm:BraveHTML', '.html:BraveHTML', '.pdf:BraveFile', '.shtml:BraveHTML'
    )
    'LibreWolf'     = @(
        'Proto:https:LibreWolfHTM', 'Proto:http:LibreWolfHTM',
        '.htm:LibreWolfHTM', '.html:LibreWolfHTM', '.pdf:LibreWolfHTM', '.shtml:LibreWolfHTM'
    )
    'Firefox'       = @(
        'Proto:https:FirefoxURL-308046B0AF4A39CB', 'Proto:http:FirefoxURL-308046B0AF4A39CB',
        '.htm:FirefoxHTML-308046B0AF4A39CB', '.html:FirefoxHTML-308046B0AF4A39CB',
        '.pdf:FirefoxPDF-308046B0AF4A39CB', '.shtml:FirefoxHTML-308046B0AF4A39CB'
    )
    'Google Chrome' = @(
        'Proto:https:ChromeHTML', 'Proto:http:ChromeHTML',
        '.htm:ChromeHTML', '.html:ChromeHTML', '.pdf:ChromeHTML', '.shtml:ChromeHTML'
    )
}

$associations = $baseAssociations
if ($Browser -and $browserMap.ContainsKey($Browser)) {
    $associations += $browserMap[$Browser]
}

$hkuSids = (& reg query HKU 2>&1) |
    Where-Object { $_ -match '^HKEY_USERS\\(S-[\d-]+|AME_UserHive_\w+)$' } |
    ForEach-Object { ($_ -replace '^HKEY_USERS\\', '') }

foreach ($sid in $hkuSids) {
    $subkeys = (& reg query "HKU\$sid" 2>&1) -join "`n"
    if ($subkeys -notmatch '(Volatile Environment|AME_UserHive_)') { continue }

    Write-Output "Setting associations for $sid..."
    & $assocScript 'Placeholder' $sid @associations
}
