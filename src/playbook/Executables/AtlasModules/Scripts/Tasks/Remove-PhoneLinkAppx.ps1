#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

Get-AppxPackage -Name 'Microsoft.YourPhone*' | Remove-AppxPackage -ErrorAction Stop
Get-AppxProvisionedPackage -Online |
    Where-Object { $_.DisplayName -eq 'Microsoft.YourPhone' } |
    Remove-AppxProvisionedPackage -Online -ErrorAction Stop
