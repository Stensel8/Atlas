#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'ProcessExplorer' -State 1 -ScriptPath $PSCommandPath

$wingetCheck = Join-Path $env:windir 'AtlasModules\Scripts\Test-WingetReady.ps1'
& $wingetCheck
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Output 'Installing Process Explorer...'
$installDir = Join-Path $env:windir 'AtlasModules\Apps\ProcessExplorer'
& winget install -e --id Microsoft.Sysinternals.ProcessExplorer --uninstall-previous `
    -l $installDir -h --accept-source-agreements --accept-package-agreements `
    --force --disable-interactivity
if ($LASTEXITCODE -ne 0) {
    Write-Output 'error: Process Explorer installation with WinGet failed.'
    if (-not $Silent) { $null = Read-Host 'Press Enter to exit' }
    exit 1
}

Write-Output 'Creating the Start menu shortcut...'
$shortcutPath = Join-Path ([Environment]::GetFolderPath('CommonStartMenu')) 'Programs\Process Explorer.lnk'
$procexpPath  = Join-Path $installDir 'procexp.exe'
try {
    $shell    = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $procexpPath
    $shortcut.Save()
} catch {
    Write-Output 'Process Explorer shortcut could not be created in the start menu!'
}

Write-Output 'Configuring Process Explorer...'
$peKey = 'HKCU:\SOFTWARE\Sysinternals\Process Explorer'
if (-not (Test-Path -LiteralPath $peKey)) { New-Item -Path $peKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $peKey -Name 'OneInstance' -Value 1 -Type DWord

$ifeoKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe'
if (-not (Test-Path -LiteralPath $ifeoKey)) { New-Item -Path $ifeoKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $ifeoKey -Name 'Debugger' -Value $procexpPath -Type String

Write-Output ''
Write-Output "The 'pcw' service in Windows is needed for Task Manager and performance counters."
Write-Output 'Disabling it matters less as you have Process Explorer, but software and Windows might have unexpected issues.'

if (-not $Silent) {
    $choice = $Host.UI.PromptForChoice('', 'Would you like to disable it?', @('&Yes', '&No'), 1)
    if ($choice -eq 0) {
        & sc.exe config pcw start=disabled | Out-Null
    }
}

Write-Output ''
Write-Output 'Finished, changes have been applied.'
if (-not $Silent) { $null = Read-Host 'Press Enter to exit' }
