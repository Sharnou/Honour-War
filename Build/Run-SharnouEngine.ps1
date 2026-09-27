param(
  [switch]$SelfTest,
  [switch]$RuntimeTest
)
$ErrorActionPreference = "Stop"

$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$manifest = Join-Path $repo "Tools\SharnouIDE\honour-war.spp.json"
$integration = Join-Path $repo "Tools\SharnouIDE\sharnou-ide-engine.integration.json"
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw "Canonical Honour War SPP manifest is missing." }
if (-not (Test-Path -LiteralPath $integration -PathType Leaf)) { throw "Sharnou IDE/Engine integration contract is missing." }

$m = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
if ($m.canonical_identity.project_id -ne "honour-war" -or $m.canonical_identity.canonical -ne $true) { throw "Canonical Honour War identity check failed." }
if ($m.ide.id -ne "Sharnou-IDE" -or $m.engine.id -ne "SharnouEngine") { throw "Sharnou IDE/Engine binding check failed." }

$policy = $m.asset_format_policy
if ($policy.runtime_visual_format -ne ".avif") { throw "AVIF-only runtime visual policy check failed." }
if ($policy.rejected_runtime_visual_formats -notcontains ".gltf" -or $policy.rejected_runtime_visual_formats -notcontains ".glb" -or $policy.rejected_runtime_visual_formats -notcontains ".ktx2") { throw "Retired GLTF/GLB/KTX2 rejection policy check failed." }

$candidates = @(
  (Join-Path $repo "Build\Runtime\SharnouEngine.exe"),
  (Join-Path $repo "Engine\SharnouEngine\bin\SharnouEngine.exe"),
  (Join-Path $repo "Tools\SharnouIDE\runtime\SharnouEngine.exe")
)
$exe = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $exe) {
  throw "SharnouEngine.exe is not present. The repository contains source/contracts only; a native Windows executable requires the self-contained Sharnou compiler declared by the Sharnou toolchain contract. No compiler, SDK, IDE, build system, or external programming tool is downloaded automatically."
}

$env:SHARNOU_IDE_SESSION = "1"
$env:SHARNOU_IDE_REPOSITORY = "https://github.com/Sharnou/Sharnou-IDE"
$env:SHARNOU_ENGINE_ID = "SharnouEngine"
$env:SHARNOU_PROJECT_ID = "honour-war"
Set-Location -LiteralPath $repo

$args = @()
if ($SelfTest) { $args += "--self-test" }
if ($RuntimeTest) { $args += "--runtime-test=300" }

& $exe @args
if ($LASTEXITCODE -ne 0) { throw "Sharnou Engine exited with code $LASTEXITCODE." }
Write-Host "SHARNOU_ENGINE_RUNTIME_PASS=$exe"
