#Requires -Version 5.1
param([switch]$Silent, [switch]$JustContext)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'ClickToDo' -State 0 -ScriptPath $PSCommandPath

Remove-ItemProperty -LiteralPath 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableClickToDo' -Force -ErrorAction SilentlyContinue
$key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
Set-ItemProperty -LiteralPath $key -Name 'DisableClickToDo' -Value 1 -Type DWord

if ($JustContext -or $Silent) { return }

Write-Output ''
Write-Output 'Click To Do has been disabled.'
$null = Read-Host 'Press Enter to exit'
