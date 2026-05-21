#Requires -Version 5.1
Push-Location -LiteralPath $PSScriptRoot
try {
    & (Join-Path $PSScriptRoot '..\dependencies\local-build.ps1') -AddLiveLog -ReplaceOldPlaybook -Removals WinverRequirement, Verification -DontOpenPbLocation
    if ($LASTEXITCODE -ne 0 -and -not $args.Count) {
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
} finally {
    Pop-Location
}
