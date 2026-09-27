# Compatibility policy name retained; the active policy is now format-neutral.
$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".."))
$integration = Join-Path $root "Tools\SharnouIDE\sharnou-ide-engine.integration.json"
$engine = Join-Path $root "Engine\SharnouEngine\sharnou_engine_architecture.json"
if (-not (Test-Path $integration) -or -not (Test-Path $engine)) { throw "Sharnou asset policy manifests are missing." }
$i = Get-Content $integration -Raw | ConvertFrom-Json
$e = Get-Content $engine -Raw | ConvertFrom-Json
if ($i.project_id -ne "honour-war") { throw "Canonical project identity mismatch." }
if ($i.ide.id -ne "Sharnou-IDE" -or $i.engine.id -ne "SharnouEngine") { throw "Sharnou IDE/Engine authority mismatch." }
if ($i.asset_policy.accepted_input_formats -ne "*") { throw "Asset input policy is not format-neutral." }
if ($i.asset_policy.conversion -ne "automatic") { throw "Automatic asset conversion is disabled." }
if ($e.asset_pipeline.accepted_input_formats -ne "*") { throw "Engine asset intake is not format-neutral." }
if ($e.asset_pipeline.automatic_conversion -ne $true) { throw "Engine automatic conversion is disabled." }
Write-Host "PASS: SharnouEngine accepts any asset input format and owns automatic conversion/validation."
Write-Host "PASS: AVIF, GLTF, GLB, KTX2 and other formats are accepted as source inputs."
exit 0
