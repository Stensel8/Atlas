# AtlasOS PowerShell Profile

# Oh My Posh — Atlas theme
$_ompCfg = Join-Path $env:APPDATA 'AtlasOS\atlas.omp.json'
if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $_ompCfg)) {
    oh-my-posh init pwsh --config $_ompCfg | Invoke-Expression
}

# zoxide — smart cd
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    zoxide init --cmd z powershell | Out-String | Invoke-Expression
}

# PSReadLine
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
Set-PSReadLineOption -Colors @{
    Command   = '#87CEEB'
    Parameter = '#98FB98'
    Operator  = '#FFB6C1'
    Variable  = '#DDA0DD'
    String    = '#FFDAB9'
    Number    = '#B0E0E6'
    Type      = '#F0E68C'
    Comment   = '#808080'
    Keyword   = '#8367c7'
    Error     = '#FF6347'
}
Set-PSReadLineKeyHandler -Key UpArrow                -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow              -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab                    -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d'             -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w'             -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d'              -Function DeleteWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow'     -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow'    -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+z'             -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y'             -Function Redo

# File utilities
function touch ($File) {
    if (Test-Path $File) { (Get-Item $File).LastWriteTime = Get-Date }
    else { New-Item $File -ItemType File | Out-Null }
}
function mkcd ($Path) { New-Item -Path $Path -ItemType Directory -Force | Out-Null; Set-Location $Path }
function ff ($Name) { Get-ChildItem -Recurse -Filter $Name -File | Select-Object -ExpandProperty FullName }
function head ($Path, $n = 10) { Get-Content $Path -Head $n }
function which ($Name) { (Get-Command $Name -ErrorAction SilentlyContinue).Source }
function ll { Get-ChildItem -Force | Format-Table Mode, LastWriteTime, Length, Name -AutoSize }
function la { Get-ChildItem | Format-Table -AutoSize }

# Process utilities
function pgrep ($Name) { Get-Process -Name $Name -ErrorAction SilentlyContinue }
function pkill ($Name) { Get-Process -Name $Name -ErrorAction SilentlyContinue | Stop-Process -Force }

# Git shortcuts
function gs    { git status }
function ga    { git add . }
function gp    { git push }
function gpull { git pull }
function gcl   { git clone @args }
function gcom  { git add .; git commit -m "$args" }
function lazyg { git add .; git commit -m "$args"; git push }

# Aliases
Set-Alias -Name unzip -Value Expand-Archive
Set-Alias -Name grep  -Value Select-String
