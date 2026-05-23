#Requires -Version 5.1
$windir = [Environment]::GetFolderPath('Windows')
& "$windir\AtlasModules\initPowerShell.ps1"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$windir\AtlasModules\Scripts\WingetCheck.ps1"
if ($LASTEXITCODE -ne 0) { exit 1 }

Clear-Host
$ErrorActionPreference = 'SilentlyContinue'

[int] $script:column = 0
[int] $separate = 30
[int] $script:lastPos = 50
[int] $script:item_count = 0
[int] $script:index = 0
[array] $script:items = @()
[bool] $script:install = $false

function Initialize-ListItem{
    param(
        [string]$checkboxText,
        [string]$package
    )
    $script:items += , @($checkboxText, $package)
}

function New-Checkbox {
    param(
        [string]$checkboxText,
        [string]$package,
        [bool]$enabled = $true
    )
    $checkbox = new-object System.Windows.Forms.checkbox
    if($script:index -eq [math]::Ceiling($script:item_count / 2)){
        $script:column = 1
        $script:lastPos = 50
    }
    if($script:column -eq 0){
        $checkbox.Location = new-object System.Drawing.Size(30, $script:lastPos)
    }
    else{
        $checkbox.Location = new-object System.Drawing.Size(($script:column * 300), $script:lastPos)
    }
    $script:lastPos += $separate
    $checkbox.Size = new-object System.Drawing.Size(250, 18)
    $checkbox.Text = $checkboxText
    $checkbox.Name = $package
    $checkbox.Enabled = $enabled

    $checkbox
}

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

# Set the size of the form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Install Software | Atlas" # Titlebar
$Form.ShowIcon = $false
$Form.MaximizeBox = $false
$Form.MinimizeBox = $false
$Form.Size = New-Object System.Drawing.Size(600, 210)
$Form.AutoSizeMode = 0
$Form.KeyPreview = $True
$Form.SizeGripStyle = 2

# Label
$Label = New-Object System.Windows.Forms.label
$Label.Location = New-Object System.Drawing.Size(11, 15)
$Label.Size = New-Object System.Drawing.Size(255, 15)
$Label.Text = "Download and install software using WinGet:"
$Form.Controls.Add($Label)


# https://winstall.app/apps/eloston.ungoogled-chromium
Initialize-ListItem "Ungoogled Chromium" "eloston.ungoogled-chromium"

# https://winstall.app/apps/Mozilla.Firefox
Initialize-ListItem "Mozilla Firefox" "Mozilla.Firefox"

# https://winstall.app/apps/Waterfox.Waterfox
Initialize-ListItem "Waterfox" "Waterfox.Waterfox"

# https://winstall.app/apps/Brave.brave
Initialize-ListItem "Brave Browser" "Brave.Brave"

# https://winstall.app/apps/Google.Chrome
Initialize-ListItem "Google Chrome" "Google.Chrome"

# https://winstall.app/apps/LibreWolf.LibreWolf
Initialize-ListItem "LibreWolf" "LibreWolf.LibreWolf"

# https://winstall.app/apps/TorProject.TorBrowser
Initialize-ListItem "Tor Browser" "TorProject.TorBrowser"

# https://winstall.app/apps/Discord.Discord
Initialize-ListItem "Discord" "Discord.Discord"

# https://winstall.app/apps/Discord.Discord.Canary
Initialize-ListItem "Discord Canary" "Discord.Discord.Canary"

# https://winstall.app/apps/Valve.Steam
Initialize-ListItem "Steam" "Valve.Steam"

# https://winstall.app/apps/Playnite.Playnite
Initialize-ListItem "Playnite" "Playnite.Playnite"

# https://winstall.app/apps/HeroicGamesLauncher.HeroicGamesLauncher
Initialize-ListItem "Heroic" "HeroicGamesLauncher.HeroicGamesLauncher"

# https://winstall.app/apps/voidtools.Everything
Initialize-ListItem "Everything" "voidtools.Everything"

# https://winstall.app/apps/Mozilla.Thunderbird
Initialize-ListItem "Mozilla Thunderbird" "Mozilla.Thunderbird"

# https://winstall.app/apps/PeterPawlowski.foobar2000
Initialize-ListItem "foobar2000" "PeterPawlowski.foobar2000"

# https://winstall.app/apps/IrfanSkiljan.IrfanView
Initialize-ListItem "IrfanView" "IrfanSkiljan.IrfanView"

# https://winstall.app/apps/Git.Git
Initialize-ListItem "Git" "Git.Git"

# https://winstall.app/apps/VideoLAN.VLC
Initialize-ListItem "VLC" "VideoLAN.VLC"

# https://winstall.app/apps/PuTTY.PuTTY
Initialize-ListItem "PuTTY" "PuTTY.PuTTY"

# https://winstall.app/apps/Ditto.Ditto
Initialize-ListItem "Ditto" "Ditto.Ditto"

# https://winstall.app/apps/7zip.7zip
Initialize-ListItem "7-Zip" "7zip.7zip"

# https://winstall.app/apps/TeamSpeakSystems.TeamSpeakClient
Initialize-ListItem "Teamspeak" "TeamSpeakSystems.TeamSpeakClient"

# https://winstall.app/apps/Spotify.Spotify
Initialize-ListItem "Spotify" "Spotify.Spotify"

# https://winstall.app/apps/OBSProject.OBSStudio
Initialize-ListItem "OBS Studio" "OBSProject.OBSStudio"

# https://winstall.app/apps/Guru3D.Afterburner
Initialize-ListItem "MSI Afterburner" "Guru3D.Afterburner"

# https://winstall.app/apps/TechPowerUp.NVCleanstall
Initialize-ListItem "NVCleanstall" "TechPowerUp.NVCleanstall"

# https://winstall.app/apps/CPUID.CPU-Z
Initialize-ListItem "CPU-Z" "CPUID.CPU-Z"

# https://winstall.app/apps/TechPowerUp.GPU-Z
Initialize-ListItem "GPU-Z" "TechPowerUp.GPU-Z"

# https://winstall.app/apps/Notepad++.Notepad++
Initialize-ListItem "Notepad++" "Notepad++.Notepad++"

# https://winstall.app/apps/Microsoft.VisualStudioCode
Initialize-ListItem "VSCode" "Microsoft.VisualStudioCode"

# https://winstall.app/apps/VSCodium.VSCodium
Initialize-ListItem "VSCodium" "VSCodium.VSCodium"

# https://winstall.app/apps/Klocman.BulkCrapUninstaller
Initialize-ListItem "BCUninstaller" "Klocman.BulkCrapUninstaller"

# https://winstall.app/apps/REALiX.HWiNFO
Initialize-ListItem "HWiNFO" "REALiX.HWiNFO"

# https://winstall.app/apps/Skillbrains.Lightshot
Initialize-ListItem "Lightshot" "Skillbrains.Lightshot"

# https://winstall.app/apps/ShareX.ShareX
Initialize-ListItem "ShareX" "ShareX.ShareX"

# https://www.microsoft.com/store/productId/9MZ95KL8MR0L?ocid=pdpshare
Initialize-ListItem "Snipping Tool" "9MZ95KL8MR0L"

# https://winstall.app/apps/valinet.ExplorerPatcher
Initialize-ListItem "ExplorerPatcher" "valinet.ExplorerPatcher"

# https://winstall.app/apps/Microsoft.PowerShell
Initialize-ListItem "Powershell 7" "Microsoft.PowerShell"

#https://winstall.app/apps/MartiCliment.UniGetUI
Initialize-ListItem "UniGetUI" "MartiCliment.UniGetUI"

if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
    # https://winget.run/pkg/StartIsBack/StartAllBack
    Initialize-ListItem "StartAllBack" "StartIsBack.StartAllBack"
} else {
    # https://winget.run/pkg/StartIsBack/StartAllBack
    Initialize-ListItem "StartIsBack" "StartIsBack.StartIsBack"
}

$script:item_count = $script:items.Length

# Getting the index for splitting into two columns
foreach($item in $script:items){
    if($script:index -eq ($script:item_count / 2)){
        $script:column = 1
    }
    $Form.Controls.Add((New-Checkbox $item[0] $item[1]))
    $script:index ++
}

if ($script:column -ne 0) {
    $script:lastPos += $separate
}

$Form.height = $script:lastPos + 80

# Dark Mode/Light Mode Toggle
$ToggleBtn = New-Object System.Windows.Forms.Button
$ToggleBtn.Location = New-Object System.Drawing.Point(500, 20)
$ToggleBtn.Size = New-Object System.Drawing.Size(80, 23)
$ToggleBtn.Add_Click({
if ($this.Text -eq "Dark Mode") {
    $this.Text = "Light Mode"
    Set-DarkMode
} else {
    $this.Text = "Dark Mode"
    Set-LightMode
}
})
# Changed into functions
function Set-DarkMode {
    $Form.BackColor = [System.Drawing.Color]::FromArgb(26, 26, 26)
    $Form.ForeColor = [System.Drawing.Color]::White
    foreach ($control in $Form.Controls) {
        if ($control.GetType().Name -eq "Checkbox") {
            $control.BackColor = [System.Drawing.Color]::FromArgb(26, 26, 26)
            $control.ForeColor = [System.Drawing.Color]::White
        }
    }
}
function Set-LightMode {
    $Form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $Form.ForeColor = [System.Drawing.Color]::Black
    foreach ($control in $Form.Controls) {
        if ($control.GetType().Name -eq "Checkbox") {
            $control.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
            $control.ForeColor = [System.Drawing.Color]::Black
        }
    }
}
# Checks the system "app" color (light or dark)
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize\"
$keyName = "AppsUseLightTheme"
function Get-SystemTheme{
    if(((Get-ItemProperty -Path $registryPath -Name $keyName).$keyName) -eq 0){
        Set-DarkMode
        $ToggleBtn.Text = "Light Mode"
    }
    else{
        Set-LightMode
        $ToggleBtn.Text = "Dark Mode"
    }
}
Get-SystemTheme

$Form.Controls.Add($ToggleBtn)

# Install Button
$lastPosWidth = $form.Width - 80 - 31
$InstallButton = new-object System.Windows.Forms.Button
$InstallButton.Location = new-object System.Drawing.Size($lastPosWidth, $script:lastPos)
$InstallButton.Size = new-object System.Drawing.Size(80, 23)
$InstallButton.Text = "Install"
$InstallButton.Add_Click({
    $checkedBoxes = $Form.Controls | Where-Object { $_ -is [System.Windows.Forms.Checkbox] -and $_.Checked }
    if ($checkedBoxes.Count -eq 0) {
        Read-MessageBox -Title "No package selected" -Body 'Please select at least one software package to install' -Icon Information -Buttons Ok | Out-Null
    }
    else {
        $script:install = $true
        $Form.Close()
    }
})
$Form.Controls.Add($InstallButton)

# Activate the form
$Form.Add_Shown({ $Form.Activate() })
[void] $Form.ShowDialog()

if ($script:install) {
    $installPackages = [System.Collections.ArrayList]::new()
    $Form.Controls | Where-Object { $_ -is [System.Windows.Forms.Checkbox] } | ForEach-Object {
        if ($_.Checked) {
            [void]$installPackages.Add($_.Name)
        }
    }

    if ($installPackages.count -ne 0) {
        Write-Host "Installing: " -ForegroundColor Yellow
        foreach ($a in $installPackages) {
            Write-Host "- " -NoNewline -ForegroundColor Blue
            Write-Host "$a"
        }
        Write-Host ""
        Start-Sleep 1
        foreach ($package in $installPackages) {
            & winget install -e --id $package --accept-package-agreements --accept-source-agreements --disable-interactivity --force -h
        }
        Write-Host ""
        pause
    }
}
