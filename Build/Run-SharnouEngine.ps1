param(
  [switch]$SelfTest,
  [switch]$RuntimeTest,
  [switch]$FullGenerate
)

$ErrorActionPreference = "Stop"
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$ide = Join-Path $repo "Tools\SharnouIDE\SharnouIDE.ps1"

if (-not (Test-Path -LiteralPath $ide -PathType Leaf)) {
  throw "Sharnou-IDE runner not found: $ide"
}

$command = if ($FullGenerate) { "full-generate" } elseif ($SelfTest) { "self-test" } elseif ($RuntimeTest) { "runtime-test" } else { "run" }

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ide -Command $command
exit $LASTEXITCODE
