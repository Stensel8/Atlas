#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
# Atlas.Core domain functions: Privilege

function Assert-AtlasAdminPrivilege {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ScriptPath,
        [string[]]$ScriptArgs = @()
    )

    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        return
    }

    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
    if ($ScriptArgs.Count -gt 0) {
        $argList += ' ' + ($ScriptArgs -join ' ')
    }

    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs -Wait -ErrorAction Stop
    } catch {
        Write-Host 'Administrator privileges are required.' -ForegroundColor Red
    }
    exit 0
}
