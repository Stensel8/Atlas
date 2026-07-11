#Requires -Version 5.1
# ============================================================================
# AtlasOS -- Disable Widgets (default)
# Disables News and Interests / Widgets via policy registry values and
# restarts Explorer to apply the change unless -NoAction is passed.
# ============================================================================

param(
    [switch]$Silent,
    [switch]$NoAction
)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Widgets' -State 0 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Applying Widgets policy...' -ForegroundColor Yellow
    $feedsKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'
    if (-not (Test-Path $feedsKey)) { New-Item -Path $feedsKey -Force | Out-Null }
    Set-ItemProperty -Path $feedsKey -Name 'EnableFeeds' -Value 0 -Type DWord -Force

    $dshKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'
    if (-not (Test-Path $dshKey)) { New-Item -Path $dshKey -Force | Out-Null }
    Set-ItemProperty -Path $dshKey -Name 'AllowNewsAndInterests' -Value 0 -Type DWord -Force

    if (-not $NoAction) {
        Write-Host '[>>] Restarting Explorer...' -ForegroundColor Yellow
        Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
    }

    if (-not $Silent) {
        Write-Host '[OK] Widgets disabled.' -ForegroundColor Green
        Read-Host 'Press Enter to exit'
    }
} catch {
    Write-Host "[!!] Failed to disable Widgets: $_" -ForegroundColor Red
    exit 1
}
