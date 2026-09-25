param(
  [ValidateSet("Release","Debug")]
  [string]$Configuration = "Release",
  [switch]$SelfTest,
  [switch]$RuntimeTest
)
$ErrorActionPreference = "Stop"

$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$candidates = @(
  (Join-Path $repo "Build\Runtime\SharnouEngine.exe"),
  (Join-Path $repo "Engine\SharnouEngine\bin\SharnouEngine.exe"),
  (Join-Path $repo "Tools\SharnouIDE\runtime\SharnouEngine.exe")
)
$exe = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1

if (-not $exe) {
  throw "SharnouEngine.exe is not present. Sharnou IDE does not install or download a compiler/build tool. Place the already-built native runtime in Build\Runtime or an approved runtime candidate path."
}

$env:SHARNOU_IDE_SESSION = "1"
$env:SHARNOU_IDE_REPOSITORY = "https://github.com/Sharnou/Sharnou-IDE"
Set-Location -LiteralPath $repo

$args = @()
if ($SelfTest) { $args += "--self-test" }
if ($RuntimeTest) { $args += "--runtime-test=300" }

& $exe @args
if ($LASTEXITCODE -ne 0) {
  throw "Sharnou Engine exited with code $LASTEXITCODE."
}

Write-Host "SHARNOU_ENGINE_RUNTIME_PASS=$exe"
