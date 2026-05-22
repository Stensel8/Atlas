#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
# System script domain functions: Performance

function Optimize-PowerShellStartup {
    # speeds up powershell startup time by 10x
    $env:path = "$([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory());" + $env:path
    [AppDomain]::CurrentDomain.GetAssemblies().Location | Where-Object { $_ } | ForEach-Object {
        Write-Host "NGENing: $(Split-Path $_ -Leaf)" -ForegroundColor Yellow
        ngen install $_ | Out-Null
    }
}

function Set-PowerSettings {
    param (
        [switch]$DisablePowerSaving,
        [switch]$DisableHibernation
    )

    if ($DisablePowerSaving) {
        & "$script:AtlasWindowsDirectory\AtlasModules\Scripts\Helpers\DisablePowerSaving.ps1" -Silent
    }

    if ($DisableHibernation) {
        & powercfg.exe /h off
        # ShowHibernateOption 0 removes Hibernate from the power menu
        $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings'
        $null = New-Item -Path $key -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -LiteralPath $key -Name 'ShowHibernateOption' -Value 0 -Type DWord
    }

    if (-not $DisablePowerSaving) {
        & powercfg.exe /setactive "381b4222-f694-41f0-9685-ff5bb260df2e"
    }
}
