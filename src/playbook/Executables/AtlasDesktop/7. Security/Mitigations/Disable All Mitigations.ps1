#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path $env:windir -ChildPath 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Mitigations' -State 0 -ScriptPath $PSCommandPath

$kernelKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
$memKey    = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
$smKey     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'

# Disable Spectre and Meltdown
if (-not (Test-Path -LiteralPath $memKey)) { New-Item -Path $memKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $memKey -Name 'FeatureSettingsOverride'     -Value 3 -Type DWord
Set-ItemProperty -LiteralPath $memKey -Name 'FeatureSettingsOverrideMask' -Value 3 -Type DWord

# Disable SEHOP
Set-ItemProperty -LiteralPath $kernelKey -Name 'DisableExceptionChainValidation' -Value 1 -Type DWord

# Initialize the bit mask by disabling CFG first, then read the mask back
Set-ProcessMitigation -System -Disable CFG 2>&1 | Out-Null

$mitigationMask = (Get-ItemProperty -LiteralPath $kernelKey -Name 'MitigationAuditOptions' -ErrorAction SilentlyContinue).MitigationAuditOptions
if ($null -ne $mitigationMask) {
    # Set every nibble to 0x2 (disabled), matches the CMD approach of replacing every digit 0-9 with '2'
    $newMask = [byte[]]($mitigationMask | ForEach-Object { 0x22 })
    Set-ItemProperty -LiteralPath $kernelKey -Name 'MitigationAuditOptions' -Value $newMask -Type Binary
    Set-ItemProperty -LiteralPath $kernelKey -Name 'MitigationOptions'      -Value $newMask -Type Binary
}

# Fix Valorant with mitigations disabled; enable CFG for specific apps
foreach ($app in @('valorant', 'valorant-win64-shipping', 'vgtray', 'vgc')) {
    Set-ProcessMitigation -Name "$app.exe" -Enable CFG 2>&1 | Out-Null
}

# Set DEP to OptIn (only for OS components)
& bcdedit.exe /set nx OptIn 2>&1 | Out-Null

# Disable file system object mitigations
if (-not (Test-Path -LiteralPath $smKey)) { New-Item -Path $smKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $smKey -Name 'ProtectionMode' -Value 0 -Type DWord

if ($Silent) { return }

Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
