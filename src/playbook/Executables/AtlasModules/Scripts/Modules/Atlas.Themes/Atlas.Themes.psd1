@{
    RootModule        = 'Atlas.Themes.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '33228c24-43cf-4e98-b599-053910bd5740'
    Author            = 'AtlasOS'
    Description       = 'Theme application: Windows theme switching, theme MRU registry state and lock screen images.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-Theme'
        'Set-ThemeMRU'
        'Set-LockscreenImage'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
