#Requires -Version 5.1

# Atlas.TasksProcs - scheduled task and process helper module.
Set-StrictMode -Version 3.0

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'ScheduledTasks.ps1'
    'Processes.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.TasksProcs domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Stop-AtlasProcessUnderRoot'
    'Stop-AtlasScheduledTaskUnderRoot'
)
