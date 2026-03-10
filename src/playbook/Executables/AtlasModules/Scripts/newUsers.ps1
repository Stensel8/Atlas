# Guard against re-running when an existing user's profile is accidentally reset by Windows.
# Each user's SID is recorded in HKLM after a successful first-time setup so that this script
# is skipped if the profile is ever recreated from the Default user template.
# This check runs BEFORE elevation so that re-runs on already-configured accounts never
# trigger a UAC prompt.
$currentUserSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$atlasUserSetupKey = "HKLM:\SOFTWARE\AtlasOS\UserSetup"
$alreadySetUp = $false
if (Test-Path $atlasUserSetupKey) {
    $setupProps = Get-ItemProperty $atlasUserSetupKey -ErrorAction SilentlyContinue
    if ($setupProps -and $setupProps.$currentUserSid -eq 1) {
        $alreadySetUp = $true
    }
}
if ($alreadySetUp) { exit 0 }

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
  Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}

$windir = [Environment]::GetFolderPath('Windows')
& "$windir\AtlasModules\initPowerShell.ps1"
$atlasDesktop = "$windir\AtlasDesktop"
$atlasModules = "$windir\AtlasModules"

$title = 'Preparing Atlas user settings...'

if (!(Test-Path $atlasDesktop) -or !(Test-Path $atlasModules)) {
    Write-Host "Atlas was about to configure user settings, but its files weren't found. :(" -ForegroundColor Red
    Read-Pause
    exit 1
}

$Host.UI.RawUI.WindowTitle = $title
Write-Host $title -ForegroundColor Yellow
Write-Host $('-' * ($title.length + 3)) -ForegroundColor Yellow
Write-Host "You'll be logged out in 10 to 20 seconds, and once you login again, your new account will be ready for use."

# Disable Windows 11 context menu & 'Gallery' in File Explorer
if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
    & "$atlasDesktop\4. Interface Tweaks\Context Menus\Windows 11\Old Context Menu (default).cmd" /silent
    & "$atlasDesktop\4. Interface Tweaks\File Explorer Customization\Gallery\Disable Gallery (default).cmd" /silent

    # Set ThemeMRU (recent themes)
    Set-Theme -Path "$([Environment]::GetFolderPath('Windows'))\Resources\Themes\atlas-v0.5.x-dark.theme"
    Set-ThemeMRU | Out-Null
}

# Set lockscreen wallpaper
Set-LockscreenImage

# Disable 'Network' in navigation pane
& "$atlasDesktop\3. General Configuration\File Sharing\Network Navigation Pane\Disable Network Navigation Pane (default).cmd" /silent

# Disable Automatic Folder Discovery
& "$atlasDesktop\4. Interface Tweaks\File Explorer Customization\Automatic Folder Discovery\Disable Automatic Folder Discovery (default).cmd" /silent

# Set visual effects
& "$atlasDesktop\4. Interface Tweaks\Visual Effects (Animations)\Atlas Visual Effects (default).cmd" /silent

# Set taskbar pins 
$valueName = "Browser"
$value = Get-ItemProperty -Path "HKLM:\SOFTWARE\AtlasOS\SetupOptions" -Name $valueName -ErrorAction Stop
$Browser = $value.$valueName
$Browser

& "$atlasModules\Scripts\taskbarPins.ps1" $Browser
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 1

# Mark this user account as having completed Atlas new-user setup so the script is
# skipped if the profile is ever accidentally recreated from the Default user template.
# Written here (at the very end, right before logoff) so it is only set after all
# setup steps above have successfully completed.
if (-not (Test-Path $atlasUserSetupKey)) {
    New-Item -Path $atlasUserSetupKey -Force | Out-Null
}
New-ItemProperty -Path $atlasUserSetupKey -Name $currentUserSid -Value 1 -PropertyType DWord -Force | Out-Null

# Leave
Start-Sleep 5 
logoff