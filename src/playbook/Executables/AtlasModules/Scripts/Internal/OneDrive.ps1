#Requires -Version 5.1
$ErrorActionPreference = 'SilentlyContinue'

Stop-Process -Name 'OneDrive' -Force

foreach ($setupExe in @(
    "$env:windir\System32\OneDriveSetup.exe",
    "$env:windir\SysWOW64\OneDriveSetup.exe"
)) {
    if (Test-Path -LiteralPath $setupExe) { & $setupExe /uninstall }
}

if (-not (Test-Path "$env:windir\System32\OneDriveSetup.exe") -and
    -not (Test-Path "$env:windir\SysWOW64\OneDriveSetup.exe")) {
    & winget uninstall --id 'Microsoft.OneDrive' --silent --accept-source-agreements 2>&1 | Out-Null
    & winget uninstall 'Microsoft OneDrive'      --silent --accept-source-agreements 2>&1 | Out-Null
}

function Remove-OneDriveUserKeys ([string]$Sid) {
    $root = "Registry::HKEY_USERS\$Sid"

    foreach ($subPath in @(
        'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\BannerStore',
        'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers',
        'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths',
        'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )) {
        Get-ChildItem -Path "$root\$subPath" -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -like '*OneDrive*' } |
            Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }

    foreach ($clsid in @('{018D5C66-4533-4307-9B53-224DE2ED1FE6}', '{A0A7DEC5-B1A7-4A47-847D-1D005787621E}')) {
        Remove-Item "$root\SOFTWARE\Classes\CLSID\$clsid"                                                            -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item "$root\SOFTWARE\Classes\WOW6432Node\CLSID\$clsid"                                               -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\$clsid"             -Force -Recurse -ErrorAction SilentlyContinue
    }

    Remove-ItemProperty "$root\Environment"                                          -Name 'OneDrive'      -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"        -Name 'OneDriveSetup' -Force -ErrorAction SilentlyContinue

    $sfPath = "$root\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    @{
        '{F42EE2D3-909F-4907-8871-4C22FC0BF756}' = '%USERPROFILE%\Documents'
        'Personal'                                 = '%USERPROFILE%\Documents'
        'Desktop'                                  = '%USERPROFILE%\Desktop'
        'My Pictures'                              = '%USERPROFILE%\Pictures'
        '{0DDD015D-B06C-45D5-8C4C-F59713854639}'  = '%USERPROFILE%\Pictures'
    }.GetEnumerator() | ForEach-Object {
        Set-ItemProperty -Path $sfPath -Name $_.Key -Value $_.Value -Type ExpandString -Force -ErrorAction SilentlyContinue
    }
}

foreach ($key in (Get-ChildItem 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue)) {
    $sid = $key.PSChildName
    if ($sid -notmatch '^S-' -and $sid -notmatch '^AME_UserHive_[^_]+$') { continue }
    $childNames = (Get-ChildItem "Registry::HKEY_USERS\$sid" -ErrorAction SilentlyContinue).PSChildName
    if ('Volatile Environment' -notin $childNames -and $sid -notmatch 'AME_UserHive_') { continue }
    Write-Output "Making changes for '$sid'..."
    Remove-OneDriveUserKeys $sid
}

Remove-Item "$env:ProgramData\Microsoft OneDrive"  -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$env:SystemDrive\OneDriveTemp"        -Force -Recurse -ErrorAction SilentlyContinue

foreach ($userDir in (Get-ChildItem "$env:SystemDrive\Users" -Directory -ErrorAction SilentlyContinue)) {
    $base = $userDir.FullName
    Remove-Item "$base\AppData\Local\Microsoft\OneDrive"                                            -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$base\OneDrive"                                                                    -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$base\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"         -Force          -ErrorAction SilentlyContinue
}

Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SyncRootManager' -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -like '*OneDrive*' } |
    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskName -like 'OneDrive Reporting Task*' -or $_.TaskName -like 'OneDrive Standalone Update Task*' } |
    Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

foreach ($clsid in @('{018D5C66-4533-4307-9B53-224DE2ED1FE6}', '{A0A7DEC5-B1A7-4A47-847D-1D005787621E}')) {
    Remove-Item "HKLM:\SOFTWARE\Classes\CLSID\$clsid"              -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\$clsid"  -Force -Recurse -ErrorAction SilentlyContinue
}
