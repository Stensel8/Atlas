#Requires -Version 5.1
param([switch]$Silent)

$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $env:windir 'AtlasModules\Scripts\Modules\AtlasOS\AtlasOS.psm1') -Force
$activeArgs = @($PSBoundParameters.GetEnumerator() |
    Where-Object { $_.Value -is [switch] -and $_.Value.IsPresent } |
    ForEach-Object { "-$($_.Key)" })
Assert-AtlasAdminPrivilege -ScriptPath $PSCommandPath -ScriptArgs $activeArgs

$memMgmt = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
$kernel   = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
$sesMgr   = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'

Set-ItemProperty -LiteralPath $memMgmt -Name 'FeatureSettingsOverride'     -Value 3 -Type DWord
Set-ItemProperty -LiteralPath $memMgmt -Name 'FeatureSettingsOverrideMask' -Value 3 -Type DWord

Set-ItemProperty -LiteralPath $kernel -Name 'DisableExceptionChainValidation' -Value 1 -Type DWord

& Set-ProcessMitigation -System -Disable CFG

$mask = (Get-ItemProperty -LiteralPath $kernel -Name 'MitigationAuditOptions' -ErrorAction SilentlyContinue).MitigationAuditOptions
if ($mask) {
    $nibbles = [System.Text.StringBuilder]::new()
    foreach ($byte in $mask) {
        $hi = ($byte -shr 4) -band 0xF
        $lo = $byte -band 0xF
        $hi = if ($hi -le 9) { 2 } else { $hi }
        $lo = if ($lo -le 9) { 2 } else { $lo }
        $null = $nibbles.Append([char]([int][char]'0' + $hi)).Append([char]([int][char]'0' + $lo))
    }
    $newMask = [byte[]]@(0..($mask.Length - 1) | ForEach-Object {
        $hi = ($mask[$_] -shr 4) -band 0xF; $lo = $mask[$_] -band 0xF
        $hi = if ($hi -le 9) { 2 } else { $hi }
        $lo = if ($lo -le 9) { 2 } else { $lo }
        ($hi -shl 4) -bor $lo
    })
    Set-ItemProperty -LiteralPath $kernel -Name 'MitigationAuditOptions' -Value $newMask -Type Binary
    Set-ItemProperty -LiteralPath $kernel -Name 'MitigationOptions'      -Value $newMask -Type Binary
}

$enableCFGApps = @('valorant', 'valorant-win64-shipping', 'vgtray', 'vgc')
foreach ($app in $enableCFGApps) {
    & Set-ProcessMitigation -Name "$app.exe" -Enable CFG -ErrorAction SilentlyContinue
}

& bcdedit.exe /set nx OptIn | Out-Null

Set-ItemProperty -LiteralPath $sesMgr -Name 'ProtectionMode' -Value 0 -Type DWord

if ($Silent) { return }
Write-Output ''
Write-Output 'Finished, please reboot your device for changes to apply.'
$null = Read-Host 'Press Enter to exit'
