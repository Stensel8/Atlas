#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
# System script domain functions: Security

function Disable-CoreIsolation {
    & ".\AtlasModules\Scripts\ScriptWrappers\Set-VbsConfig.ps1" -DisableAllVBS
}

function Disable-Mitigations {
    $kernelKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
    $memKey    = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    $smKey     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'

    # Disable Spectre and Meltdown mitigations
    $null = New-Item -Path $memKey -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -LiteralPath $memKey -Name 'FeatureSettingsOverride'     -Value 3 -Type DWord
    Set-ItemProperty -LiteralPath $memKey -Name 'FeatureSettingsOverrideMask' -Value 3 -Type DWord

    # Disable SEHOP (Structured Exception Handler Overwrite Protection)
    Set-ItemProperty -LiteralPath $kernelKey -Name 'DisableExceptionChainValidation' -Value 1 -Type DWord

    # Disable CFG system-wide to obtain the current mitigation bitmask, then set all nibbles to 0x2 (disabled)
    Set-ProcessMitigation -System -Disable CFG 2>&1 | Out-Null
    $mitigationMask = (Get-ItemProperty -LiteralPath $kernelKey -Name 'MitigationAuditOptions' -ErrorAction SilentlyContinue).MitigationAuditOptions
    if ($null -ne $mitigationMask) {
        $newMask = [byte[]]($mitigationMask | ForEach-Object { 0x22 })
        Set-ItemProperty -LiteralPath $kernelKey -Name 'MitigationAuditOptions' -Value $newMask -Type Binary
        Set-ItemProperty -LiteralPath $kernelKey -Name 'MitigationOptions'      -Value $newMask -Type Binary
    }

    # Valorant (and its anti-cheat) require CFG even when mitigations are disabled globally
    foreach ($app in @('valorant', 'valorant-win64-shipping', 'vgtray', 'vgc')) {
        Set-ProcessMitigation -Name "$app.exe" -Enable CFG 2>&1 | Out-Null
    }

    # Set DEP to OptIn so only opted-in processes get Data Execution Prevention
    & bcdedit.exe /set nx OptIn 2>&1 | Out-Null

    # Disable object manager symbolic link protection
    $null = New-Item -Path $smKey -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -LiteralPath $smKey -Name 'ProtectionMode' -Value 0 -Type DWord
}
