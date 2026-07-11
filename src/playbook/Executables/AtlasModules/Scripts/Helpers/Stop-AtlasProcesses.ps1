#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$executablesRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$tasksProcsModule = Join-Path -Path $executablesRoot -ChildPath 'AtlasModules\Scripts\Modules\Atlas.TasksProcs\Atlas.TasksProcs.psd1'
if (-not (Test-Path -LiteralPath $tasksProcsModule -PathType Leaf)) {
    throw "Atlas.TasksProcs module '$tasksProcsModule' is missing."
}

Import-Module $tasksProcsModule -Force

$windir = [Environment]::GetFolderPath('Windows')
$targetRoots = @(
    Join-Path -Path $windir -ChildPath 'AtlasModules'
    Join-Path -Path $windir -ChildPath 'AtlasDesktop'
) | ForEach-Object {
    try {
        ([System.IO.Path]::GetFullPath($_)).TrimEnd('\')
    }
    catch {
        $null
    }
} | Where-Object { $_ }

if (-not $targetRoots) {
    return
}

$rootsLower = $targetRoots | ForEach-Object { ($_ + '\').ToLowerInvariant() }
Stop-AtlasProcessUnderRoot -RootsLower $rootsLower
Stop-AtlasScheduledTaskUnderRoot -RootsLower $rootsLower

$timerExePath = Join-Path -Path $windir -ChildPath 'AtlasModules\Tools\SetTimerResolution.exe'
if (Test-Path -LiteralPath $timerExePath -PathType Leaf) {
    try {
        $stream = [System.IO.File]::Open($timerExePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Dispose()
    }
    catch {
        Stop-AtlasProcessUnderRoot -RootsLower $rootsLower
        Start-Sleep -Milliseconds 500
    }
}
