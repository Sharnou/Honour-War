param(
    [ValidateSet("validate","compile","self-test","runtime-test","run")]
    [string]$Command = "run",
    [int]$RuntimeTestSeconds = 300
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ide = Join-Path $root "Tools\SharnouIDE\SharnouIDE.ps1"

if (-not (Test-Path -LiteralPath $ide -PathType Leaf)) {
    throw "Sharnou IDE launcher not found: $ide"
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ide -Command $Command -RuntimeTestSeconds $RuntimeTestSeconds
exit $LASTEXITCODE
