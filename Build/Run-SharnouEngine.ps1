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

if (-not $env:VCPKG_ROOT) {
  $vcpkgCommand = Get-Command vcpkg -ErrorAction SilentlyContinue
  if ($vcpkgCommand) {
    $env:VCPKG_ROOT = Split-Path $vcpkgCommand.Source -Parent
  }
}
if (-not $env:VCPKG_ROOT -or -not (Test-Path (Join-Path $env:VCPKG_ROOT "scripts\buildsystems\vcpkg.cmake"))) {
  throw "vcpkg is required. Set VCPKG_ROOT or install vcpkg for Visual Studio 2022."
}

cmake --preset vs2022-x64
cmake --build $build --config $Configuration --parallel

$exe = Join-Path $build $Configuration "SharnouEngine.exe"
if (-not (Test-Path $exe)) {
  throw "Sharnou Engine executable was not produced: $exe"
}

& $exe "--self-test"
if ($LASTEXITCODE -ne 0) {
  throw "Sharnou Engine native self-test failed with exit code $LASTEXITCODE."
}

Write-Host "SHARNOU_ENGINE_BUILD_AND_SELFTEST_PASS=$exe"
