@{
    RootModule        = 'Atlas.Registry.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '2d3bdc85-ad80-4f56-8139-eda9e87bf9ae'
    Author            = 'AtlasOS'
    Description       = 'Registry and user path helpers: user hive enumeration, known folder resolution and system drive detection.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Get-RegUserPaths'
        'Get-UserPath'
        'Get-SystemDrive'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
