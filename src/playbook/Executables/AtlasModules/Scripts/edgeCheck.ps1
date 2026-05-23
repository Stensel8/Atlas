#Requires -Version 5.1
param(
    [switch]$Silent,
    [switch]$EdgeOnly,
    [switch]$WebView
)

$dashes = '-' * 101
$edgeExe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$edgeInstalled = Test-Path -LiteralPath $edgeExe

# /edgeonly: succeed silently if edge is already present, otherwise fall through to prompt
if ($EdgeOnly -and $edgeInstalled) { exit 0 }

Write-Output $dashes

$installEdge = -not $edgeInstalled -and -not $WebView
if ($installEdge) {
    if ($Silent) {
        Write-Output 'Edge is missing but silent mode is active. Exiting...'
        exit 1
    }
    Write-Output 'Microsoft Edge is required to use this script.'
    Write-Output 'In the future, if you no longer want to use this feature, you can use the disable script and uninstall Edge.'
    $choice = Read-Host 'Would you like to install Edge? [Y/N]'
    if ($choice -notmatch '^[Yy]$') {
        Write-Output ''
        exit 0
    }
}

$remover = "$env:windir\AtlasModules\Scripts\ScriptWrappers\Set-EdgeInstall.ps1"
if (-not (Test-Path -LiteralPath $remover -PathType Leaf)) {
    Write-Output "Error: '$remover' not found."
    exit 1
}

$removerArgs = @('-NonInteractive', '-InstallWebView')
if ($installEdge) { $removerArgs += '-InstallEdge' }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $remover @removerArgs

if ($LASTEXITCODE -eq 1) {
    Write-Output 'Something went wrong while trying to update/install Edge or WebView.'
    if (-not $Silent) {
        Write-Output 'Press any key to exit...'
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
    exit 1
}

Write-Output $dashes
