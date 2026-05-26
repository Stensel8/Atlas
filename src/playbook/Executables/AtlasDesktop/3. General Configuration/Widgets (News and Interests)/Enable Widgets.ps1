#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Enable Widgets
# Re-enables News and Interests / Widgets by removing the policy keys.
# Requires Edge or WebView2 for Widgets to function (checked via Test-EdgeInstall.ps1).
# Restarts Explorer and opens the taskbar Settings page to let the user
# toggle the widget icon. -NoAction skips the Explorer restart.
# ============================================================================

param(
    [switch]$Silent,
    [switch]$NoAction
)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Widgets' -State 1 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Checking Edge/WebView2 requirement...' -ForegroundColor Yellow
    $edgeCheck = Join-Path $env:windir 'AtlasModules\Scripts\Test-EdgeInstall.ps1'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $edgeCheck
    if ($LASTEXITCODE -ne 0) { exit 1 }

    Write-Host '[>>] Enabling Widgets...' -ForegroundColor Yellow
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' `
        -Name 'EnableFeeds' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' `
        -Name 'AllowNewsAndInterests' -ErrorAction SilentlyContinue

    if (-not $NoAction) {
        Write-Host '[>>] Restarting Explorer...' -ForegroundColor Yellow
        Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        Start-Process 'ms-settings:taskbar'
    }

    if (-not $Silent) {
        Write-Host '[OK] Widgets enabled. Toggle the icon in the taskbar Settings page.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to enable Widgets: $_" -ForegroundColor Red
    exit 1
}
