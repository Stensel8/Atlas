@{
    RootModule        = 'Atlas.TasksProcs.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '029d4005-f448-486f-8448-ba654f6e59e0'
    Author            = 'AtlasOS'
    Description       = 'Scheduled task and process helpers: stop processes and scheduled tasks under given root paths.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Stop-AtlasProcessUnderRoot'
        'Stop-AtlasScheduledTaskUnderRoot'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
