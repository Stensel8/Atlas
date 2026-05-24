#Requires -Version 5.1
param([switch]$Silent, [switch]$NoAction)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'WebSearch' -State 1 -ScriptPath $PSCommandPath

$wingetCheck = Join-Path $env:windir 'AtlasModules\Scripts\Test-WingetReady.ps1'
if (Test-Path -LiteralPath $wingetCheck) {
    & $wingetCheck
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

Write-Output 'Enabling Web Search & Search Highlights...'

$wsPol = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
$locationPref = if (-not $Silent) {
    $Host.UI.PromptForChoice('', 'Allow web search to use your location for results?', @('&Yes', '&No'), 1)
} else { 1 }
if ($locationPref -eq 0) {
    Remove-ItemProperty -LiteralPath $wsPol -Name 'AllowSearchToUseLocation' -ErrorAction SilentlyContinue
} else {
    if (-not (Test-Path -LiteralPath $wsPol)) { New-Item -Path $wsPol -Force | Out-Null }
    New-ItemProperty -LiteralPath $wsPol -Name 'AllowSearchToUseLocation' -Value 0 -PropertyType DWord -Force | Out-Null
}

# On Windows 11, disabled search indexing causes a graphical bug with web search
$build = [System.Environment]::OSVersion.Version.Build
if ($build -ge 22000 -and -not $Silent) {
    $wsearch = Get-Service -Name 'wsearch' -ErrorAction SilentlyContinue
    if ($wsearch -and $wsearch.Status -eq 'Stopped') {
        Write-Output ''
        Write-Output 'On Windows 11, disabled search indexing causes a visual bug in web search.'
        $indexChoice = $Host.UI.PromptForChoice('', 'Enable search indexing to fix it?', @('&Yes', '&No'), 1)
        if ($indexChoice -eq 0) {
            $enableIndexing = Join-Path $env:windir 'AtlasDesktop\3. General Configuration\Search Indexing\Enable Search Indexing.ps1'
            if (Test-Path -LiteralPath $enableIndexing) { & $enableIndexing -Silent }
        }
    }
}

Write-Output 'Installing the Bing search provider...'
& winget.exe install -e --id '9NZBF4GT040C' --uninstall-previous -h `
    --accept-source-agreements --accept-package-agreements --force --disable-interactivity 2>&1 | Out-Null

Invoke-AtlasSettingsPage -Operation unhide -Page 'search-permissions'

foreach ($name in @('BingSearchEnabled', 'IsAADCloudSearchEnabled', 'IsDeviceSearchHistoryEnabled',
                     'IsMSACloudSearchEnabled', 'SafeSearchMode')) {
    Remove-ItemProperty -LiteralPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' `
        -Name $name -ErrorAction SilentlyContinue
}
Remove-ItemProperty -LiteralPath $wsPol -Name 'ConnectedSearchUseWeb'     -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $wsPol -Name 'DisableWebSearch'           -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath $wsPol -Name 'EnableDynamicContentInWSB'  -ErrorAction SilentlyContinue
Remove-ItemProperty -LiteralPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' `
    -Name 'DisableSearchBoxSuggestions' -ErrorAction SilentlyContinue

New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings' `
    -Name 'IsDynamicSearchBoxEnabled' -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' `
    -Name 'SearchboxTaskbarMode' -Value 2 -PropertyType DWord -Force | Out-Null

if (-not $NoAction) {
    Stop-Process -Name 'SearchHost' -Force -ErrorAction SilentlyContinue
    Stop-Process -Name 'explorer'   -Force -ErrorAction SilentlyContinue
    Start-Process 'explorer.exe'
}

if ($Silent) { return }
Write-Output ''
Write-Output 'Web Search and Search Highlights are now enabled.'
$null = Read-Host 'Press Enter to exit'
