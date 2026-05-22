#Requires -Version 5.1
# AtlasOS domain functions: Admin

function Assert-AtlasAdminPrivilege {
    param(
        [Parameter(Mandatory)][string]$ScriptPath,
        [string[]]$ScriptArgs = @()
    )

    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
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
