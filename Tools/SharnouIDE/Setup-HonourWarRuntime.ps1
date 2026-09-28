param(
    [switch]$RunSelfTest,
    [int]$RuntimeTestSeconds = 60
)

$ErrorActionPreference = "Stop"
$ideRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $ideRoot "..\.."))
Set-Location -LiteralPath $repoRoot

function Require-File([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required runtime setup file is missing: $Path"
    }
}

Write-Host "=== Honour War / SharnouEngine runtime setup ===" -ForegroundColor Cyan
Write-Host "Project: honour-war"
Write-Host "IDE: Sharnou-IDE"
Write-Host "Engine: SharnouEngine"
Write-Host "Target: 3D HD MMORPG/ARPG"

Require-File (Join-Path $repoRoot "Tools\SharnouIDE\honour-war.spp.json")
Require-File (Join-Path $repoRoot "Tools\SharnouIDE\project\main.spp")
Require-File (Join-Path $repoRoot "Tools\SharnouIDE\Compile-Spp.ps1")
Require-File (Join-Path $repoRoot "Tools\sharnou_honour_war_runtime_generator.py")
Require-File (Join-Path $repoRoot "data\honour_war_content_catalog.json")

Write-Host "[1/5] Validating Sharnou stack policy..." -ForegroundColor Yellow
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot "ci\sharnou-stack-policy.ps1")
if ($LASTEXITCODE -ne 0) { throw "Sharnou stack policy failed: $LASTEXITCODE" }

Write-Host "[2/5] Validating glTF/KTX2/AVIF policy..." -ForegroundColor Yellow
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot "ci\sharnou-avif-policy.ps1")
if ($LASTEXITCODE -ne 0) { throw "Asset-format policy failed: $LASTEXITCODE" }

Write-Host "[3/5] Compiling canonical Sharnou-IDE SPP..." -ForegroundColor Yellow
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot "Tools\SharnouIDE\Compile-Spp.ps1") `
    -Source (Join-Path $repoRoot "Tools\SharnouIDE\project\main.spp") `
    -Output (Join-Path $repoRoot "Build\Runtime\honour-war.sppc.json")
if ($LASTEXITCODE -ne 0) { throw "SPP compilation failed: $LASTEXITCODE" }

Write-Host "[4/5] Materializing deterministic runtime scene descriptors..." -ForegroundColor Yellow
python (Join-Path $repoRoot "Tools\sharnou_honour_war_runtime_generator.py") `
    (Join-Path $repoRoot "data\honour_war_content_catalog.json") `
    --output (Join-Path $repoRoot "Build\Runtime\Generated\honour_war_runtime_asset_plan.json")
if ($LASTEXITCODE -ne 0) { throw "Runtime asset generation failed: $LASTEXITCODE" }

$engineCandidates = @(
    (Join-Path $repoRoot "Build\Runtime\SharnouEngine.exe"),
    (Join-Path $repoRoot "Engine\SharnouEngine\bin\SharnouEngine.exe"),
    (Join-Path $repoRoot "Tools\SharnouIDE\runtime\SharnouEngine.exe")
)
$enginePath = $engineCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1

if (-not $enginePath) {
    Write-Warning "No approved SharnouEngine.exe is present in the configured runtime candidates."
    Write-Host "Runtime descriptors and SPP bytecode are prepared, but executable runtime execution is NOT claimed." -ForegroundColor Yellow
    Write-Host "No Unity, Unreal, Visual Studio, MSBuild, Windows SDK, CMake, vcpkg, or external tool download was attempted."
    exit 2
}

Write-Host "[5/5] SharnouEngine executable found: $enginePath" -ForegroundColor Green
$env:SHARNOU_IDE_SESSION = "1"
$env:SHARNOU_IDE_REPOSITORY = "https://github.com/Sharnou/Sharnou-IDE"
$env:SHARNOU_ENGINE_ID = "SharnouEngine"
$env:SHARNOU_PROJECT_ID = "honour-war"

if ($RunSelfTest) {
    & $enginePath "--self-test"
    if ($LASTEXITCODE -ne 0) { throw "SharnouEngine self-test failed: $LASTEXITCODE" }
}

& $enginePath "--runtime-test=$RuntimeTestSeconds"
if ($LASTEXITCODE -ne 0) { throw "SharnouEngine runtime test failed: $LASTEXITCODE" }

Write-Host "PASS: Honour War runtime setup and SharnouEngine runtime test completed." -ForegroundColor Green
exit 0
