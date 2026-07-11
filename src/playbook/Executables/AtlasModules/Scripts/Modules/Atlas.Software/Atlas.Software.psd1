@{
    RootModule        = 'Atlas.Software.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '5791222b-7c9b-4640-8035-44912bfe4be6'
    Author            = 'AtlasOS'
    Description       = 'Software servicing: CBS client updates and feature ID configuration via ViVeTool.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Update-ClientCBS'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
