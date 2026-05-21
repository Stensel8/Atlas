#Requires -Version 5.1
$windir = [Environment]::GetFolderPath('Windows')

# Add Atlas' PowerShell modules
$env:PSModulePath += ";$windir\AtlasModules\Scripts\Modules"