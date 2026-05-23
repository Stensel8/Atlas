#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$uninstallScript = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasDesktop\6. Advanced Configuration\Process Explorer\Uninstall Process Explorer.ps1'
if (Test-Path -LiteralPath $uninstallScript -PathType Leaf) {
    & $uninstallScript -Silent
}
else {
    Write-Warning "Process Explorer uninstall script '$uninstallScript' was not found; continuing upgrade cleanup."
}

Get-Process -Name 'taskmgr' -ErrorAction SilentlyContinue | Stop-Process -Force
