#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force

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
& $indexConf -CleanPolicies
& $indexConf -Include -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
& $indexConf -Include -Path "$env:windir\AtlasDesktop"
& $indexConf -Exclude -Path "$env:SystemDrive\Users"

$gatherKey     = 'HKLM:\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex'
$gatherSubPath = 'Software\Microsoft\Windows Search\Gather\Windows\SystemIndex'

# This key is owned by TrustedInstaller/WSearch and denies write access to Administrators.
# We use SeTakeOwnershipPrivilege (available in elevated admin tokens) to take ownership,
# grant Administrators SetValue, then write RespectPowerModes. WSearch is stopped at this point.
try {
    # SeTakeOwnershipPrivilege is present in elevated tokens but inactive until explicitly enabled.
    # Without this, OpenSubKey with TakeOwnership rights throws SecurityException.
    $priv = [System.Diagnostics.Process].GetMember('SetPrivilege', 42)[0]
    $priv.Invoke($null, @('SeTakeOwnershipPrivilege', 2))

    $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        $gatherSubPath,
        [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
        [System.Security.AccessControl.RegistryRights]::TakeOwnership
    )
    $acl = $regKey.GetAccessControl([System.Security.AccessControl.AccessControlSections]::None)
    $acl.SetOwner([System.Security.Principal.NTAccount]'BUILTIN\Administrators')
    $regKey.SetAccessControl($acl)
    # Re-read ACL now that Administrators owns the key, then grant SetValue
    $acl = $regKey.GetAccessControl()
    $rule = [System.Security.AccessControl.RegistryAccessRule]::new(
        [System.Security.Principal.NTAccount]'BUILTIN\Administrators',
        [System.Security.AccessControl.RegistryRights]::SetValue,
        [System.Security.AccessControl.AccessControlType]::Allow
    )
    $acl.SetAccessRule($rule)
    $regKey.SetAccessControl($acl)
    $regKey.Close()
    Set-ItemProperty -LiteralPath $gatherKey -Name 'RespectPowerModes' -Value 1 -Type DWord
} catch {
    Write-Warning "Could not set RespectPowerModes on WSearch gather key (TrustedInstaller-owned): $_"
}

& $indexConf -Start

$searchKey = 'HKLM:\SOFTWARE\Microsoft\Windows Search'
if (-not (Test-Path -LiteralPath $searchKey)) { New-Item -Path $searchKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $searchKey -Name 'SetupCompletedSuccessfully' -Value 0 -Type DWord

if ($Silent) { return }

Write-Output ''
Write-Output 'Minimal Search Indexing has been configured.'
$null = Read-Host 'Press Enter to exit'
