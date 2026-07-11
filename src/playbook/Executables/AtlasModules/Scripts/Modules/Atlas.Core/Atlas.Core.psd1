@{
    RootModule        = 'Atlas.Core.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'aa751fda-b37a-4e35-8972-f78e3abee806'
    Author            = 'AtlasOS'
    Description       = 'Core Atlas framework: privilege checks, settings state, device helpers and shared UI helpers.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        # Privilege
        'Assert-AtlasAdminPrivilege'
        # Settings
        'Set-AtlasSettingState'
        'Invoke-AtlasSettingsPage'
        # Devices
        'Enable-AtlasDevice'
        'Disable-AtlasDevice'
        # UI
        'Write-Title'
        'Read-Pause'
        'Read-MessageBox'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
