param(
  [ValidateSet("Debug","Release")]
  [string]$Configuration = "Release"
)
$ErrorActionPreference = "Stop"

$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$engine = Join-Path $repo "Engine\SharnouEngine"
$build = Join-Path $engine "out\build\vs2022-x64"

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
  throw "CMake is required for Sharnou Engine."
}
if (-not (Get-Command msbuild -ErrorAction SilentlyContinue)) {
  throw "Visual Studio Community 2022 MSBuild is required for Sharnou Engine."
}

cmake --preset vs2022-x64
cmake --build $build --config $Configuration --parallel

$exe = Join-Path $build $Configuration "SharnouEngine.exe"
if (-not (Test-Path $exe)) {
  throw "Sharnou Engine executable was not produced: $exe"
}

Write-Host "SHARNOU_ENGINE_BUILD_PASS=$exe"
