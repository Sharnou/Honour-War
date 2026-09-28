param(
    [string]$EngineRoot = "",
    [int]$RuntimeTestSeconds = 60
)

$ErrorActionPreference = "Stop"
$GameRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))

Write-Host "=== Honour War COMPLETE RUNTIME BUILD ===" -ForegroundColor Cyan
Write-Host "Game root: $GameRoot"
Write-Host "Canonical project: honour-war"
Write-Host "IDE: Sharnou-IDE"
Write-Host "Engine: SharnouEngine"
Write-Host "Target: Windows 10 x64 / standalone 3D HD MMORPG/ARPG"

$Registry = Join-Path $GameRoot "Tools\sharnou_asset_registry.py"
$Cache = Join-Path $GameRoot "Tools\sharnou_resource_cache.py"
$Generator = Join-Path $GameRoot "Tools\sharnou_honour_war_runtime_generator.py"
$Catalog = Join-Path $GameRoot "data\honour_war_content_catalog.json"

foreach ($required in @($Registry,$Cache,$Generator,$Catalog)) {
    if (!(Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Required runtime component missing: $required"
    }
}

if ([string]::IsNullOrWhiteSpace($EngineRoot)) {
    $candidates = @(
        (Join-Path $GameRoot "..\Sharnou-Engine-main"),
        (Join-Path $GameRoot "..\Latest\Sharnou-Engine-main"),
        (Join-Path $GameRoot "..\Latest\Sharnou-Engine-main-old"),
        (Join-Path $GameRoot "..\..\Sharnou-Engine-main")
    )
    $EngineRoot = $candidates |
        ForEach-Object { [System.IO.Path]::GetFullPath($_) } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
        Select-Object -First 1
}

if (!$EngineRoot) {
    throw "SharnouEngine repository not found. Supply -EngineRoot."
}

$EngineRoot = [System.IO.Path]::GetFullPath($EngineRoot)

Write-Host "[1/7] Sharnou policy validation..." -ForegroundColor Yellow
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $GameRoot "ci\sharnou-stack-policy.ps1")
if ($LASTEXITCODE -ne 0) { throw "Sharnou stack policy failed." }

Write-Host "[2/7] glTF/KTX2/AVIF validation..." -ForegroundColor Yellow
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $GameRoot "ci\sharnou-avif-policy.ps1")
if ($LASTEXITCODE -ne 0) { throw "Asset format policy failed." }

Write-Host "[3/7] SPP compile..." -ForegroundColor Yellow
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $GameRoot "Tools\SharnouIDE\Compile-Spp.ps1") -Source (Join-Path $GameRoot "Tools\SharnouIDE\project\main.spp") -Output (Join-Path $GameRoot "Build\Runtime\honour-war.sppc.json")
if ($LASTEXITCODE -ne 0) { throw "SPP compilation failed." }

Write-Host "[4/7] Generate Honour War runtime scene descriptors..." -ForegroundColor Yellow
python $Generator $Catalog --output (Join-Path $GameRoot "Build\Runtime\Generated\honour_war_runtime_asset_plan.json")
if ($LASTEXITCODE -ne 0) { throw "Runtime descriptor generation failed." }

Write-Host "[5/7] Build standalone SharnouEngine.exe..." -ForegroundColor Yellow
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $GameRoot "Tools\SharnouIDE\Build-StandaloneRuntime.ps1") -EngineRoot $EngineRoot -RuntimeTestSeconds $RuntimeTestSeconds
if ($LASTEXITCODE -ne 0) { throw "Standalone runtime build failed." }

Write-Host "[6/7] Rebuild runtime registry and resource cache..." -ForegroundColor Yellow
& python $Registry "." --output (Join-Path $GameRoot "Build\Runtime\honour_war_asset_registry.json")
if ($LASTEXITCODE -ne 0) { throw "Asset registry failed." }

& python $Cache (Join-Path $GameRoot "Build\Runtime\honour_war_asset_registry.json") --output (Join-Path $GameRoot "Build\Runtime\honour_war_resource_cache.json")
if ($LASTEXITCODE -ne 0) { throw "Resource cache failed." }

$runtime = Join-Path $GameRoot "Build\Runtime\SharnouEngine.exe"
if (!(Test-Path -LiteralPath $runtime -PathType Leaf)) {
    throw "Final SharnouEngine.exe is missing: $runtime"
}

Write-Host "[7/7] Final native runtime verification..." -ForegroundColor Yellow

$bytes=[System.IO.File]::ReadAllBytes($runtime)
if ($bytes.Length -lt 0x40 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) {
    throw "Final executable is not a valid PE image."
}
$peOffset=[BitConverter]::ToInt32($bytes,0x3C)
if ($peOffset -lt 0 -or $peOffset+6 -gt $bytes.Length -or $bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset+1] -ne 0x45) {
    throw "Final executable PE header is invalid."
}
$machine=[BitConverter]::ToUInt16($bytes,$peOffset+4)
if ($machine -ne 0x8664) {
    throw ("Final executable is not x64. Machine=0x{0:X4}" -f $machine)
}

$hash=(Get-FileHash -LiteralPath $runtime -Algorithm SHA256).Hash
$registry=Get-Content (Join-Path $GameRoot "Build\Runtime\honour_war_asset_registry.json") -Raw | ConvertFrom-Json
$plan=Get-Content (Join-Path $GameRoot "Build\Runtime\Generated\honour_war_runtime_asset_plan.json") -Raw | ConvertFrom-Json

$evidence=[ordered]@{
    schema="honour-war.complete-runtime.v1"
    project="honour-war"
    ide="Sharnou-IDE"
    engine="SharnouEngine"
    architecture="GFC-inspired standalone 3D HD MMORPG/ARPG engine"
    platform="Windows 10 x64"
    executable=(Resolve-Path $runtime).Path
    executable_size=$bytes.Length
    executable_sha256=$hash
    pe_machine=("0x{0:X4}" -f $machine)
    native_runtime=$true
    generated_scene_count=[int]$plan.scene_count
    registry_asset_count=[int]$registry.assets.Count
    runtime_formats=@{
        scene=@(".gltf",".glb")
        texture_3d=@(".ktx2")
        visual_2d=@(".avif")
        gltf_texture_extension="KHR_texture_basisu"
    }
    external_engine_required=$false
    external_toolchain_downloaded=$false
}
$evidencePath=Join-Path $GameRoot "Build\Runtime\honour-war-complete-runtime.json"
$evidence | ConvertTo-Json -Depth 10 | Set-Content $evidencePath -Encoding UTF8

Write-Host ""
Write-Host "COMPLETE RUNTIME PREPARATION PASSED." -ForegroundColor Green
Write-Host "Executable: $runtime"
Write-Host "Generated scenes: $($plan.scene_count)"
Write-Host "Registered runtime assets: $($registry.assets.Count)"
Write-Host "Executable SHA-256: $hash"
Write-Host "Evidence: $evidencePath"
