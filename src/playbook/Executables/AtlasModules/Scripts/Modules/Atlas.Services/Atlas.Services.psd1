@{
    RootModule        = 'Atlas.Services.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '7c470ab4-4b3e-41b8-871c-aa05bb9af7d3'
    Author            = 'AtlasOS'
    Description       = 'Service and driver configuration: startup types, network discovery services and service state backups.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-AtlasServiceStartup'
        'Show-AtlasServiceWarning'
        'Enable-NetworkDiscoveryServices'
        'Export-AtlasServicesBackup'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
