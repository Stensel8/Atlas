@{
    ExcludeRules = @(
        # Plural nouns are semantically correct in this codebase (e.g. Disable-Mitigations,
        # Remove-PrintingFromContextMenus). Renaming would break YAML callsites.
        'PSUseSingularNouns',

        # AME Wizard runs scripts non-interactively. ShouldProcess (-WhatIf/-Confirm)
        # adds no value and would require [CmdletBinding(SupportsShouldProcess)] on
        # every Set-/Remove-/New- function across the entire codebase.
        'PSUseShouldProcessForStateChangingFunctions',

        # We deliberately use UTF-8 WITHOUT BOM (LF line endings, POSIX-compatible).
        # BOM causes issues in some AME Wizard parsing contexts.
        'PSUseBOMForUnicodeEncodedFile'
    )
}
