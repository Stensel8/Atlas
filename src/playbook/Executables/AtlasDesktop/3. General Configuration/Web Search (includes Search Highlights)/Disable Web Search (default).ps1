#Requires -Version 5.1
param([switch]$Silent, [switch]$NoAction)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'WebSearch' -State 0 -ScriptPath $PSCommandPath

Invoke-AtlasSettingsPage -Operation hide -Page 'search-permissions'

$wsPol = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
if (-not (Test-Path -LiteralPath $wsPol)) { New-Item -Path $wsPol -Force | Out-Null }
New-ItemProperty -LiteralPath $wsPol -Name 'AllowSearchToUseLocation'  -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $wsPol -Name 'ConnectedSearchUseWeb'      -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $wsPol -Name 'DisableWebSearch'           -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $wsPol -Name 'EnableDynamicContentInWSB'  -Value 0 -PropertyType DWord -Force | Out-Null

New-ItemProperty -LiteralPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' `
    -Name 'BingSearchEnabled'      -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' `
    -Name 'SearchboxTaskbarMode'   -Value 1 -PropertyType DWord -Force | Out-Null

$ss = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'
if (-not (Test-Path -LiteralPath $ss)) { New-Item -Path $ss -Force | Out-Null }
New-ItemProperty -LiteralPath $ss -Name 'IsAADCloudSearchEnabled'        -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $ss -Name 'IsDeviceSearchHistoryEnabled'   -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $ss -Name 'IsMSACloudSearchEnabled'        -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $ss -Name 'SafeSearchMode'                 -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -LiteralPath $ss -Name 'IsDynamicSearchBoxEnabled'      -Value 0 -PropertyType DWord -Force | Out-Null

$polExp = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
if (-not (Test-Path -LiteralPath $polExp)) { New-Item -Path $polExp -Force | Out-Null }
New-ItemProperty -LiteralPath $polExp -Name 'DisableSearchBoxSuggestions' -Value 1 -PropertyType DWord -Force | Out-Null

if (-not $NoAction) {
    Stop-Process -Name 'SearchHost' -Force -ErrorAction SilentlyContinue
    Stop-Process -Name 'explorer'   -Force -ErrorAction SilentlyContinue
    Start-Process 'explorer.exe'
}

Get-AppxPackage -AllUsers 'Microsoft.BingSearch*' | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

if ($Silent) { return }
Write-Output ''
Write-Output 'Web Search has been disabled.'
$null = Read-Host 'Press Enter to exit'
