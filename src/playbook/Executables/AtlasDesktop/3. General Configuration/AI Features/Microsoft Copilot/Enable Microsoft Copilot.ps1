#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Enable Microsoft Copilot
# Re-enables Copilot. On Windows 11 24H2+, IsCopilotAvailable may be absent,
# meaning the sidebar was replaced by the standalone app; in that case the app
# is installed via winget (id: 9NHT9RB2F4HD) instead of toggling the button.
# Requires Edge or WebView2 (checked via Test-EdgeInstall.ps1).
# Restarts Explorer unless -NoAction is passed.
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

Set-AtlasSettingState -SettingName 'Copilot' -State 1 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Checking Edge/WebView2 requirement...' -ForegroundColor Yellow
    $edgeCheck = Join-Path $env:windir 'AtlasModules\Scripts\Test-EdgeInstall.ps1'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $edgeCheck -EdgeOnly
    if ($LASTEXITCODE -ne 0) { exit 1 }

    Write-Host '[>>] Enabling Copilot...' -ForegroundColor Yellow

    # IsCopilotAvailable = 0 means sidebar Copilot is present; otherwise install the app
    $isCopilotAvailable = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\Shell\Copilot' `
        -Name 'IsCopilotAvailable' -ErrorAction SilentlyContinue).IsCopilotAvailable

    $appInstalled = $false
    if ($isCopilotAvailable -eq 0) {
        Write-Host '[!] Taskbar Copilot unavailable; installing the Copilot app instead.' -ForegroundColor Yellow

        $wingetCheck = Join-Path $env:windir 'AtlasModules\Scripts\Test-WingetReady.ps1'
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $wingetCheck -NoDashes
        if ($LASTEXITCODE -ne 0) { exit 1 }

        & winget.exe install -e --id '9NHT9RB2F4HD' --uninstall-previous -h `
            --accept-source-agreements --accept-package-agreements --force --disable-interactivity | Out-Null
        $appInstalled = $true
    } else {
        $advKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        if (-not (Test-Path $advKey)) { New-Item -Path $advKey -Force | Out-Null }
        Set-ItemProperty -Path $advKey -Name 'ShowCopilotButton' -Value 1 -Type DWord -Force
    }

    Remove-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' `
        -Name 'TurnOffWindowsCopilot' -ErrorAction SilentlyContinue

    if (-not $NoAction) {
        Write-Host '[>>] Restarting Explorer...' -ForegroundColor Yellow
        Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
    }

    if (-not $Silent) {
        if ($appInstalled) {
            Write-Host '[OK] Copilot app installed. Find it in the Start Menu.' -ForegroundColor Green
        } else {
            Write-Host '[OK] Copilot enabled.' -ForegroundColor Green
        }
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to enable Copilot: $_" -ForegroundColor Red
    exit 1
}
