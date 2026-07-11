#Requires -Version 5.1

# Atlas.Shortcuts - shortcut creation helpers.
Set-StrictMode -Version 3.0

function New-AtlasShortcut {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string]$Source,
        [Parameter(Mandatory = $True)][ValidateNotNullOrEmpty()][string]$Destination,
        [ValidateNotNullOrEmpty()][string]$WorkingDir,
        [ValidateNotNullOrEmpty()][string]$Arguments,
        [ValidateNotNullOrEmpty()][string]$Icon,
        [switch]$IfExist
    )

    if (!(Test-Path $Source) -and !(Get-Command $Source -ErrorAction SilentlyContinue)) {
        throw "Source '$source' not found."
    }

    if ($IfExist -and !(Test-Path $Destination)) {
        return
    }

    if (!$WorkingDir) {
        try {
            $WorkingDir = Split-Path $Source
        } catch {
            $WorkingDir = [Environment]::GetFolderPath('System')
        }
    }

    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($Destination)
    $Shortcut.TargetPath = $Source
    $Shortcut.WorkingDirectory = $WorkingDir
    if ($Icon) { $Shortcut.IconLocation = $Icon }
    if ($Arguments) { $Shortcut.Arguments = $Arguments }
    $Shortcut.Save()
}

Export-ModuleMember -Function New-AtlasShortcut
