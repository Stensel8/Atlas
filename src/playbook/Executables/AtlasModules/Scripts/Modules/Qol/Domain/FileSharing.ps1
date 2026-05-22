#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
# QOL domain functions: FileSharing context menu entries

$script:_fileSharingClsid = '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}'
$script:_fileSharingClasses = @(
    '*'
    'Directory\Background'
    'Directory'
    'Drive'
    'LibraryFolder\background'
    'UserLibraryFolder'
)

function Initialize-HkcrDrive {
    if (-not (Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    }
}

function Disable-GiveAccessToContextMenu {
    Initialize-HkcrDrive
    foreach ($class in $script:_fileSharingClasses) {
        Remove-Item -LiteralPath "HKCR:\$class\shellex\ContextMenuHandlers\Sharing" -Force -ErrorAction SilentlyContinue
    }
}

function Enable-GiveAccessToContextMenu {
    Initialize-HkcrDrive
    foreach ($class in $script:_fileSharingClasses) {
        $path = "HKCR:\$class\shellex\ContextMenuHandlers\Sharing"
        $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -LiteralPath $path -Name '(Default)' -Value $script:_fileSharingClsid -Force
    }
}
