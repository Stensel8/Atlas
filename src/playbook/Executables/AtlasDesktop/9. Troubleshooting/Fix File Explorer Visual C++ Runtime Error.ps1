#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

if (-not $Silent) {
    Write-Output 'This will remove the legacy File Explorer search redirect used by older Atlas builds.'
    Write-Output 'It can fix blank Microsoft Visual C++ Runtime Library errors from explorer.exe.'
    Write-Output ''
    $null = Read-Host 'Press Enter to continue'
}

$clsid = '{1d64637d-31e9-4b06-9124-e83fb178ac6e}'
$treatAs = "CLSID\$clsid\TreatAs"

Write-Output 'Restoring modern File Explorer search...'

foreach ($path in @(
    "HKLM:\SOFTWARE\Classes\$treatAs"
    "HKLM:\SOFTWARE\Classes\WOW6432Node\$treatAs"
    "HKLM:\SOFTWARE\WOW6432Node\Classes\$treatAs"
    "HKCU:\Software\Classes\$treatAs"
    "HKCU:\Software\Classes\WOW6432Node\$treatAs"
)) {
    Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
}

$null = New-PSDrive -Name 'HKU' -PSProvider Registry -Root 'HKEY_USERS' -ErrorAction SilentlyContinue
$userSids = (Get-ChildItem -LiteralPath 'HKU:\' -ErrorAction SilentlyContinue).PSChildName |
    Where-Object { $_ -match '^S-1-5-21-' }
foreach ($sid in $userSids) {
    Remove-Item -LiteralPath "HKU:\$sid\Software\Classes\$treatAs" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath "HKU:\$sid\Software\Classes\WOW6432Node\$treatAs" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output 'Restarting File Explorer...'
Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
Start-Process -FilePath (Join-Path $env:windir 'explorer.exe')

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished.'
$null = Read-Host 'Press Enter to exit'
