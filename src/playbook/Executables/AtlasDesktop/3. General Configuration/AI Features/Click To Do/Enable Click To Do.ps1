#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'ClickToDo' -State 1 -ScriptPath $PSCommandPath

try {
    Write-Host '[>>] Enabling Click To Do...' -ForegroundColor Yellow
    Remove-ItemProperty -LiteralPath 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' `
        -Name 'DisableClickToDo' -ErrorAction SilentlyContinue
    Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' `
        -Name 'DisableClickToDo' -ErrorAction SilentlyContinue

    if ($Silent) { return }

    Write-Host '[OK] Click To Do enabled.' -ForegroundColor Green
    $null = Read-Host 'Press Enter to exit'
} catch {
    Write-Host "[!!] Failed to enable Click To Do: $_" -ForegroundColor Red
    exit 1
}
