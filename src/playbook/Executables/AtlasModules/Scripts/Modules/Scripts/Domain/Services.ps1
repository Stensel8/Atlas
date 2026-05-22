#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
# System script domain functions: Services

function Enable-NetworkDiscoveryServices {
    # LanmanWorkstation (SMB) is a hard dependency for network discovery
    Set-Service -Name 'LanmanWorkstation' -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name 'LanmanWorkstation' -ErrorAction SilentlyContinue

    Set-Service -Name 'eventlog'  -StartupType Automatic -ErrorAction SilentlyContinue
    Set-Service -Name 'fdPHost'   -StartupType Manual    -ErrorAction SilentlyContinue
    Set-Service -Name 'FDResPub'  -StartupType Manual    -ErrorAction SilentlyContinue
    Set-Service -Name 'lmhosts'   -StartupType Manual    -ErrorAction SilentlyContinue
    Set-Service -Name 'netman'    -StartupType Manual    -ErrorAction SilentlyContinue
    Set-Service -Name 'SSDPSRV'   -StartupType Manual    -ErrorAction SilentlyContinue

    # NlaSvc startup differs between Win10 and Win11
    $build = [int](Get-CimInstance -ClassName Win32_OperatingSystem -Property BuildNumber).BuildNumber
    $nlaSvcStartup = if ($build -lt 22000) { 'Automatic' } else { 'Manual' }
    Set-Service -Name 'NlaSvc' -StartupType $nlaSvcStartup -ErrorAction SilentlyContinue
}
