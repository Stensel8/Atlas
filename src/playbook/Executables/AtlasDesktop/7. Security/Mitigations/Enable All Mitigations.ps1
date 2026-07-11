#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\Atlas.Core\Atlas.Core.psd1') -Force

$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

Set-AtlasSettingState -SettingName 'Mitigations' -State 2 -ScriptPath $PSCommandPath

if (-not $Silent) {
    Write-Output 'WARNING: This will force enable all security mitigations for improved security.'
    Write-Output '         This will slow down performance, and worsen compatibility. It is'
    Write-Output "         recommended to use 'Set Windows Default Mitigations.ps1' instead."
    Write-Output ''
    $null = Read-Host 'Press Enter to continue'
}

$memMgmtKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
$kernelKey  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
$sessionKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
$virtKey    = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization'

# Spectre/Meltdown
if (-not (Test-Path -LiteralPath $memMgmtKey)) { New-Item -Path $memMgmtKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $memMgmtKey -Name 'FeatureSettingsOverrideMask' -Value 3 -Type DWord
$cpuName = (Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1).Name
if     ($cpuName -match 'Intel') { Set-ItemProperty -LiteralPath $memMgmtKey -Name 'FeatureSettingsOverride' -Value 0  -Type DWord }
elseif ($cpuName -match 'AMD')   { Set-ItemProperty -LiteralPath $memMgmtKey -Name 'FeatureSettingsOverride' -Value 64 -Type DWord }

# SEHOP
if (-not (Test-Path -LiteralPath $kernelKey)) { New-Item -Path $kernelKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $kernelKey -Name 'DisableExceptionChainValidation' -Value 0 -Type DWord

# CFG
Set-ProcessMitigation -System -Enable CFG

# MitigationOptions -- set all nibbles to 0x1 (decimal nibbles -> 1, letter nibbles preserved)
try {
    $current = (Get-ItemProperty -LiteralPath $kernelKey -Name 'MitigationAuditOptions' -ErrorAction Stop).MitigationAuditOptions
    $updated = $current | ForEach-Object {
        $hi = ($_ -shr 4) -band 0x0F
        $lo = $_ -band 0x0F
        [byte](((if ($hi -le 9) { 1 } else { $hi }) -shl 4) -bor (if ($lo -le 9) { 1 } else { $lo }))
    }
} catch {
    $updated = [byte[]]([byte]0x11 * 9)
}
Set-ItemProperty -LiteralPath $kernelKey -Name 'MitigationAuditOptions' -Value $updated -Type Binary
Set-ItemProperty -LiteralPath $kernelKey -Name 'MitigationOptions'      -Value $updated -Type Binary

# DEP
& bcdedit.exe /set nx AlwaysOn | Out-Null

# File system mitigations
if (-not (Test-Path -LiteralPath $sessionKey)) { New-Item -Path $sessionKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $sessionKey -Name 'ProtectionMode' -Value 1 -Type DWord

# Hyper-V
if (-not (Test-Path -LiteralPath $virtKey)) { New-Item -Path $virtKey -Force | Out-Null }
Set-ItemProperty -LiteralPath $virtKey -Name 'MinVmVersionForCpuBasedMitigations' -Value '1.0' -Type String

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
