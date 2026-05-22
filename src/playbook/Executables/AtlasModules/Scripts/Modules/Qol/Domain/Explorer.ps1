#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
# QOL domain functions: Explorer

function Remove-ExtractFromContextMenu {
    $blockedKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
    $null = New-Item -Path $blockedKey -Force -ErrorAction SilentlyContinue
    foreach ($clsid in @(
        '{b8cdcb65-b1bf-4b42-9428-1dfdb7ee92af}'
        '{BD472F60-27FA-11cf-B8B4-444553540000}'
        '{EE07CEF5-3441-4CFB-870A-4002C724783A}'
        '{D12E3394-DE4B-4777-93E9-DF0AC88F8584}'
    )) {
        New-ItemProperty -LiteralPath $blockedKey -Name $clsid -Value '' -PropertyType String -Force | Out-Null
    }
}

# Function to remove printing from context menus

function Remove-PrintingFromContextMenus {
    # HKCR: is not a built-in PS drive; must be mapped before accessing HKEY_CLASSES_ROOT paths
    if (-not (Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    }
    $null = New-Item -Path 'HKCR:\SystemFileAssociations\image\shell\print' -Force -ErrorAction SilentlyContinue
    New-ItemProperty -LiteralPath 'HKCR:\SystemFileAssociations\image\shell\print' -Name 'ProgrammaticAccessOnly' -Value '' -PropertyType String -Force | Out-Null
    foreach ($class in @(
        'batfile', 'cmdfile', 'docxfile', 'fonfile', 'htmlfile', 'inffile', 'inifile',
        'JSEFile', 'otffile', 'pfmfile', 'regfile', 'rtffile', 'ttcfile', 'ttffile',
        'txtfile', 'VBEFile', 'VBSFile', 'WSFFile'
    )) {
        $null = New-Item -Path "HKCR:\$class\shell\print" -Force -ErrorAction SilentlyContinue
        New-ItemProperty -LiteralPath "HKCR:\$class\shell\print" -Name 'ProgrammaticAccessOnly' -Value '' -PropertyType String -Force | Out-Null
    }
    if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
        foreach ($subKey in @('Print', 'PrintTo')) {
            $appxKey = "HKCR:\AppX4ztfk9wxr86nxmzzq47px0nh0e58b8fw\Shell\$subKey"
            $null = New-Item -Path $appxKey -Force -ErrorAction SilentlyContinue
            New-ItemProperty -LiteralPath $appxKey -Name 'LegacyDisable'          -Value '' -PropertyType String -Force | Out-Null
            New-ItemProperty -LiteralPath $appxKey -Name 'ProgrammaticAccessOnly' -Value '' -PropertyType String -Force | Out-Null
            New-ItemProperty -LiteralPath $appxKey -Name 'HideBasedOnVelocityId'  -Value 6527944 -PropertyType DWord -Force | Out-Null
        }
    }
}

# Function to show more details by default on file transfers

function Show-MoreDetailsOnTransfers {
    # EnthusiastMode 1 makes the copy/move dialog show detailed speed and time info by default
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager' -Name 'EnthusiastMode' -Value 1 -Type DWord -Force
}

# Function to debloat Send-To context menu

function Set-SendToContextMenu {
    & "$env:windir\AtlasModules\Scripts\Internal\DebloatSendToContextMenu.ps1" -Disable @('Documents', 'Mail Recipient', 'Fax recipient', 'Bluetooth')
}

# Function to disable use of check boxes to select items

function Disable-UseCheckBoxesToSelectItems {
    # AutoCheckSelect 0 removes the checkboxes that appear on hover in File Explorer
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'AutoCheckSelect' -Value 0 -Type DWord -Force
}

# Function to hide Gallery in File Explorer

function Hide-GalleryInFileExplorer {
    # IsPinnedToNameSpaceTree 0 hides Gallery from the File Explorer navigation pane
    $null = New-Item -Path 'HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -LiteralPath 'HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}' -Name 'System.IsPinnedToNameSpaceTree' -Value 0 -Type DWord
}

# Function to disable searching for invalid shortcuts

function Disable-SearchingForInvalidShortcuts {
    # NoResolveSearch and NoResolveTrack stop Explorer from hunting for moved files when a shortcut breaks
    $path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'NoResolveSearch' -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'NoResolveTrack' -Value 1 -Type DWord -Force
}

# Function to disable network navigation pane in Explorer

function Disable-NetworkNavigationPaneInExplorer {
    # IsPinnedToNameSpaceTree 0 hides the Network item from the File Explorer navigation pane
    $null = New-Item -Path 'HKCU:\SOFTWARE\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -LiteralPath 'HKCU:\SOFTWARE\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}' -Name 'System.IsPinnedToNameSpaceTree' -Value 0 -Type DWord
}

# Function to not show Office files in Quick Access

function Hide-OfficeFilesInQuickAccess {
    # ShowCloudFilesInQuickAccess 0 hides OneDrive and SharePoint files from the Quick Access sidebar
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowCloudFilesInQuickAccess' -Value 0 -Type DWord -Force
}

# Function to always show the full context menu on items

function Show-FullContextMenuOnItems {
    # MultipleInvokePromptMinimum controls how many files trigger the 'are you sure?' prompt; 100 means never prompt
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'MultipleInvokePromptMinimum' -Value 100 -Type DWord -Force
}

# Function to hide recent items in Quick Access

function Hide-RecentItems {
    # Stop Explorer from tracking and showing recently opened files
    $explorerPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
    Set-ItemProperty -Path $explorerPath -Name 'ShowFrequent' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $explorerPath -Name 'ShowRecent' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "$explorerPath\Advanced" -Name 'Start_TrackDocs' -Value 0 -Type DWord -Force

    # Policy keys enforce the setting so it cannot be toggled back in Folder Options
    $policyPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    $null = New-Item -Path $policyPath -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $policyPath -Name 'ClearRecentDocsOnExit' -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $policyPath -Name 'NoRecentDocsHistory' -Value 1 -Type DWord -Force

    # NoRemoteDestinations stops apps from adding entries to the Jump List / recent files list
    $null = New-Item -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'NoRemoteDestinations' -Value 1 -Type DWord -Force
}

# Function to minimize mouse hover time for item info

function Set-MouseHoverTimeForItemInfo {
    # MouseHoverTime is in milliseconds; 20ms means tooltips appear almost instantly
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MouseHoverTime' -Value '20' -Type String -Force
}

# Function to configure File Explorer to open to This PC

function Set-FileExplorerToThisPC {
    # LaunchTo 1 means open to This PC; 2 would be Quick Access (Windows default)
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -Value 1 -Type DWord -Force
}

# Function to remove previous versions from Explorer

function Remove-PreviousVersionsFromExplorer {
    # Removes the Previous Versions tab from file properties; Shadow Copy is not used on Atlas
    Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'NoPreviousVersionsPage' -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\PreviousVersions' -Name 'DisableLocalPage' -Force -ErrorAction SilentlyContinue
}

# Function to remove shortcut text

function Remove-ShortcutText {
    # ShortcutNameTemplate with "%s.lnk" keeps the original name without adding "- Shortcut" suffix
    $null = New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates' -Name 'ShortcutNameTemplate' -Value '"%s.lnk"' -Type String -Force
}

# Function to configure Explorer to show all files with file extensions

function Show-AllFilesWithExtensions {
    # Hidden 1 shows hidden files; HideFileExt 0 shows file extensions for all file types
    $path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Set-ItemProperty -Path $path -Name 'Hidden' -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'HideFileExt' -Value 0 -Type DWord -Force
}

# Function to use compact mode in File Explorer

function Enable-CompactMode {
    # UseCompactMode 1 reduces row height in File Explorer, fitting more items on screen
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'UseCompactMode' -Value 1 -Type DWord -Force
}

# Function to not show Edge tabs in Alt-Tab
