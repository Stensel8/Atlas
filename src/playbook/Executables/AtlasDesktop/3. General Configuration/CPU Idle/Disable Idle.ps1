#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$proc = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
if ([int]$proc.NumberOfLogicalProcessors -gt [int]$proc.NumberOfCores) {
    Write-Output ''
    Write-Output 'Hyper-Threading / SMT Detected'
    Write-Output '-------------------------------------------'
    Write-Output 'You should not disable idle states when this feature is enabled'
    Write-Output 'as it makes overall CPU performance much worse.'
    Write-Output ''
    Write-Output 'It can be disabled in BIOS. Instead, consider disabling C-states in BIOS.'
    $null = Read-Host 'Press Enter to exit'
    exit 1
}

if (-not $Silent) {
    Write-Output 'This forces your CPU to work at its maximum speed always, ensure you have good cooling.'
    Write-Output ''
    Write-Output 'Task Manager will display CPU usage as 100% always, due to how Task Manager calculates CPU percentage.'
    Write-Output 'It does not occur in other tools such as Process Explorer, System Informer or Process Hacker.'
    Write-Output ''
    $null = Read-Host 'Press Enter to continue'
}

Set-AtlasSettingState -SettingName 'CpuIdle' -State 0 -ScriptPath $PSCommandPath

& powercfg.exe /setacvalueindex scheme_current sub_processor '5d76a2ca-e8c0-402f-a133-2158492d58ad' 1
& powercfg.exe /setactive scheme_current

if ($Silent) { return }
Write-Output ''
Write-Output 'CPU idle has been disabled.'
$null = Read-Host 'Press Enter to exit'
