#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$indexConf = Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Set-SearchIndexConfig.ps1'
if (-not (Test-Path -LiteralPath $indexConf -PathType Leaf)) {
    if (-not $Silent) {
        Write-Output "The 'Set-SearchIndexConfig.ps1' script was not found in AtlasModules."
        $null = Read-Host 'Press Enter to exit'
    }
    exit 1
}

Set-AtlasSettingState -SettingName 'Indexing' -State 1 -ScriptPath $PSCommandPath

if (-not $Silent) { Write-Output 'Configuring minimal search indexing...' }

& $indexConf -Stop

$gatherKey = 'HKLM:\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex'

# WSearch registry keys under Gather\SystemIndex and Sites\LocalHost are owned by
# TrustedInstaller with DENY ACEs for Administrators. Enable SeTakeOwnershipPrivilege (9)
# and SeRestorePrivilege (17) via RtlAdjustPrivilege (ntdll.dll), take ownership of each
# key, grant FullControl to Administrators so Set-SearchIndexConfig writes succeed.
try {
    if (-not ([System.Management.Automation.PSTypeName]'AtlasNtPrivilege').Type) {
        Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public static class AtlasNtPrivilege {
    [DllImport("ntdll.dll")]
    public static extern uint RtlAdjustPrivilege(int priv, bool enable, bool thread, out bool prev);
}
'@
    }
    $prev = $false
    [AtlasNtPrivilege]::RtlAdjustPrivilege(9,  $true, $false, [ref]$prev) | Out-Null
    [AtlasNtPrivilege]::RtlAdjustPrivilege(17, $true, $false, [ref]$prev) | Out-Null

    $lm     = [Microsoft.Win32.Registry]::LocalMachine
    $admins = [System.Security.Principal.NTAccount]'BUILTIN\Administrators'

    foreach ($sp in @(
        'Software\Microsoft\Windows Search\Gather\Windows\SystemIndex',
        'Software\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost',
        'Software\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Paths',
        'Software\Microsoft\Windows Search\Gather\Windows\SystemIndex\Sites\LocalHost\Exclusions'
    )) {
        $k = $lm.OpenSubKey($sp, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
            [System.Security.AccessControl.RegistryRights]::TakeOwnership)
        if (-not $k) { continue }
        $acl = $k.GetAccessControl([System.Security.AccessControl.AccessControlSections]::None)
        $acl.SetOwner($admins)
        $k.SetAccessControl($acl)
        $k.Close()

        $k = $lm.OpenSubKey($sp, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
            [System.Security.AccessControl.RegistryRights]::ChangePermissions)
        if (-not $k) { continue }
        $acl = $k.GetAccessControl()
        $acl.SetAccessRule([System.Security.AccessControl.RegistryAccessRule]::new(
            $admins,
            [System.Security.AccessControl.RegistryRights]::FullControl,
            [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
            [System.Security.AccessControl.PropagationFlags]::None,
            [System.Security.AccessControl.AccessControlType]::Allow))
        $k.SetAccessControl($acl)
        $k.Close()
    }
} catch {
    Write-Warning "Could not grant registry access to WSearch keys: $_"
}

& $indexConf -CleanPolicies
& $indexConf -Include -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
& $indexConf -Include -Path "$env:windir\AtlasDesktop"
& $indexConf -Exclude -Path "$env:SystemDrive\Users"

Set-ItemProperty -LiteralPath $gatherKey -Name 'RespectPowerModes' -Value 1 -Type DWord -ErrorAction SilentlyContinue

& $indexConf -Start

$searchKey = 'HKLM:\SOFTWARE\Microsoft\Windows Search'
if (-not (Test-Path -LiteralPath $searchKey)) { New-Item -Path $searchKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $searchKey -Name 'SetupCompletedSuccessfully' -Value 0 -Type DWord

if ($Silent) { return }

Write-Output ''
Write-Output 'Minimal Search Indexing has been configured.'
$null = Read-Host 'Press Enter to exit'
