param(
    [ValidateSet("validate","compile","build-runtime","self-test","runtime-test","full-generate","run")]
    [string]$Command = "run",
    [int]$RuntimeTestSeconds = 300
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ide = Join-Path $root "Tools\SharnouIDE\SharnouIDE.ps1"

if (-not (Test-Path -LiteralPath $ide -PathType Leaf)) {
    throw "Sharnou IDE launcher not found: $ide"
}

if ($Command -eq "build-runtime") {
    $builder = Join-Path $root "Tools\SharnouIDE\Build-StandaloneRuntime.ps1"
    if (!(Test-Path -LiteralPath $builder -PathType Leaf)) {
        throw "Standalone runtime builder missing: $builder"
    }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $builder -RuntimeTestSeconds $RuntimeTestSeconds
    exit $LASTEXITCODE
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ide -Command $Command -RuntimeTestSeconds $RuntimeTestSeconds
exit $LASTEXITCODE
