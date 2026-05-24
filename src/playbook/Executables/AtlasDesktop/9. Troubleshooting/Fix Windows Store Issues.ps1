#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

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

$helper = Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Helpers\Fix-Store.ps1'
if (-not (Test-Path -LiteralPath $helper -PathType Leaf)) {
    Write-Host "[!!] Fix-Store helper not found at '$helper'." -ForegroundColor Red
    if (-not $Silent) { $null = Read-Host 'Press Enter to exit' }
    exit 1
}

& $helper @PSBoundParameters
