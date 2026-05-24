#Requires -Version 5.1
param (
    [string]$Browser
)
$ErrorActionPreference = 'Stop'
if (!$Browser) {
    $ArgString = "`"${Env:WinDir}\AtlasModules\Scripts\Set-TaskbarPins.ps1`""
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-NoProfile -ExecutionPolicy RemoteSigned -File $ArgString `"$Browser`""
    $Trigger = New-ScheduledTaskTrigger -AtLogon
    $Principal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel Highest

    Register-ScheduledTask -TaskName "TaskBarPinsDefault" -Action $Action -Trigger $Trigger -Principal $Principal -Force
}
else {
    $ArgString = "`"${Env:WinDir}\AtlasModules\Scripts\Set-TaskbarPins.ps1`""
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-NoProfile -ExecutionPolicy RemoteSigned -File $ArgString `"$Browser`""
    $Trigger = New-ScheduledTaskTrigger -AtLogon
    $Principal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel Highest

    Register-ScheduledTask -TaskName "TaskBarPins" -Action $Action -Trigger $Trigger -Principal $Principal -Force
}


