param(
    [string]$EngineRoot = "",
    [int]$RuntimeTestSeconds = 60,
    [switch]$SkipRuntimeTest
)

$ErrorActionPreference = "Stop"
$gameRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))

if ([string]::IsNullOrWhiteSpace($EngineRoot)) {
    $candidates = @(
        (Join-Path $gameRoot "..\Sharnou-Engine-main"),
        (Join-Path $gameRoot "..\Latest\Sharnou-Engine-main"),
        (Join-Path $gameRoot "..\Latest\Sharnou-Engine-main-old"),
        (Join-Path $gameRoot "..\..\Sharnou-Engine-main")
    )
    $EngineRoot = $candidates |
        ForEach-Object { [System.IO.Path]::GetFullPath($_) } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
        Select-Object -First 1
}

if (-not $EngineRoot) {
    throw "SharnouEngine source repository could not be located. Supply -EngineRoot explicitly."
}

$EngineRoot = [System.IO.Path]::GetFullPath($EngineRoot)
$engineBuild = Join-Path $EngineRoot "toolchain\build-sharnou-engine.ps1"

if (!(Test-Path -LiteralPath $engineBuild -PathType Leaf)) {
    throw "Standalone SharnouEngine build script is missing: $engineBuild"
}

$engineOutput = Join-Path $gameRoot "Build\Runtime\SharnouEngine.exe"
New-Item -ItemType Directory -Force -Path (Split-Path $engineOutput -Parent) | Out-Null

Write-Host "=== Build Honour War standalone SharnouEngine runtime ===" -ForegroundColor Cyan
Write-Host "Game:   honour-war"
Write-Host "Engine: $EngineRoot"
Write-Host "Output: $engineOutput"

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $engineBuild -Output $engineOutput
if ($LASTEXITCODE -ne 0) {
    throw "SharnouEngine standalone build failed: $LASTEXITCODE"
}

if (!(Test-Path -LiteralPath $engineOutput -PathType Leaf)) {
    throw "Build reported success but no SharnouEngine.exe was produced."
}

function Test-WindowsX64PE([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 0x40) { return $false }
    if ($bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { return $false }
    $peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
    if ($peOffset -lt 0 -or $peOffset + 6 -gt $bytes.Length) { return $false }
    if ($bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset + 1] -ne 0x45 -or $bytes[$peOffset + 2] -ne 0x00 -or $bytes[$peOffset + 3] -ne 0x00) { return $false }
    return ([BitConverter]::ToUInt16($bytes, $peOffset + 4) -eq 0x8664)
}

$runtimeFile = Get-Item -LiteralPath $engineOutput
if (!(Test-WindowsX64PE $engineOutput)) {
    throw "SharnouEngine.exe is not a valid Windows x64 PE image."
}

$hash = (Get-FileHash -LiteralPath $engineOutput -Algorithm SHA256).Hash
Write-Host "PASS: Windows x64 executable verified." -ForegroundColor Green
Write-Host ("PASS: executable size = {0:N0} bytes" -f $runtimeFile.Length) -ForegroundColor Green
Write-Host "PASS: SHA-256 = $hash" -ForegroundColor Green

$env:SHARNOU_IDE_SESSION = "1"
$env:SHARNOU_IDE_REPOSITORY = "https://github.com/Sharnou/Sharnou-IDE"
$env:SHARNOU_ENGINE_ID = "SharnouEngine"
$env:SHARNOU_PROJECT_ID = "honour-war"

Write-Host "[1/2] Native SharnouEngine self-test..." -ForegroundColor Yellow
& $engineOutput --self-test
if ($LASTEXITCODE -ne 0) {
    throw "Native SharnouEngine self-test failed: $LASTEXITCODE"
}

if (!$SkipRuntimeTest) {
    Write-Host "[2/2] Native SharnouEngine runtime test..." -ForegroundColor Yellow
    & $engineOutput "--runtime-test=$RuntimeTestSeconds"
    if ($LASTEXITCODE -ne 0) {
        throw "Native SharnouEngine runtime test failed: $LASTEXITCODE"
    }
}

$manifestPath = Join-Path $gameRoot "Build\Runtime\honour-war.native-runtime.json"
$manifest = [ordered]@{
    schema = "honour-war.native-runtime.v1"
    project = "honour-war"
    engine = "SharnouEngine"
    ide = "Sharnou-IDE"
    architecture = "GFC-inspired standalone 3D HD MMORPG/ARPG engine"
    platform = "Windows 10 x64"
    executable = (Resolve-Path $engineOutput).Path
    size = $runtimeFile.Length
    sha256 = $hash
    verified_windows_x64_pe = $true
    runtime_test_seconds = if ($SkipRuntimeTest) { 0 } else { $RuntimeTestSeconds }
    formats = [ordered]@{
        scene = @(".gltf",".glb")
        texture_3d = @(".ktx2")
        visual_2d = @(".avif")
        gltf_extension = "KHR_texture_basisu"
    }
    standalone = $true
    external_engine_required = $false
}
$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Write-Host "PASS: standalone Honour War runtime package prepared." -ForegroundColor Green
Write-Host "Runtime manifest: $manifestPath"
