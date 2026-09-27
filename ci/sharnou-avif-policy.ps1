# Compatibility policy name retained; the active policy validates the SharnouEngine glTF/KTX2/AVIF split.
$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".."))
$integration = Join-Path $root "Tools\SharnouIDE\sharnou-ide-engine.integration.json"
$engine = Join-Path $root "Engine\SharnouEngine\sharnou_engine_architecture.json"

if (-not (Test-Path $integration) -or -not (Test-Path $engine)) {
    throw "Sharnou asset policy manifests are missing."
}

$i = Get-Content $integration -Raw | ConvertFrom-Json
$e = Get-Content $engine -Raw | ConvertFrom-Json

if ($i.project_id -ne "honour-war") { throw "Canonical project identity mismatch." }
if ($i.canonical -ne $true) { throw "Integration contract is not canonical." }
if ($i.ide.id -ne "Sharnou-IDE" -or $i.engine.id -ne "SharnouEngine") {
    throw "Sharnou IDE/Engine authority mismatch."
}
if ($i.asset_policy.accepted_input_formats -ne "*") { throw "Asset input policy is not format-neutral." }
if ($i.asset_policy.conversion -ne "automatic") { throw "Automatic asset conversion is disabled." }
if ($i.formats.source_intake -ne "any-registered-format") { throw "Universal IDE source intake is disabled." }
if ($i.glTF_texture_extension -ne "KHR_texture_basisu") { throw "KHR_texture_basisu contract is missing." }
if (@($i.formats."3d_scene").Count -ne 2 -or @($i.formats."3d_scene") -notcontains ".gltf" -or @($i.formats."3d_scene") -notcontains ".glb") {
    throw "glTF/GLB runtime scene container contract is incomplete."
}
if (@($i.formats."3d_textures").Count -ne 1 -or $i.formats."3d_textures"[0] -ne ".ktx2") {
    throw "KTX2 runtime texture contract is incomplete."
}
if (@($i.formats.ui_2d).Count -ne 1 -or $i.formats.ui_2d[0] -ne ".avif") {
    throw "AVIF 2D visual contract is incomplete."
}
if (@($i.asset_policy.accepted_generated_raster_formats).Count -ne 1 -or $i.asset_policy.accepted_generated_raster_formats[0] -ne ".AVIF") {
    throw "Generated raster output is not AVIF-only."
}

if ($e.canonical_project_id -ne "honour-war") { throw "Engine canonical project identity mismatch." }
if ($e.authoring_controller -ne "Sharnou-IDE") { throw "Engine authoring controller mismatch." }
if ($e.runtime_authority -ne "SharnouEngine") { throw "Engine runtime authority mismatch." }
if ($e.asset_pipeline.accepted_input_formats -ne "*") { throw "Engine asset intake is not format-neutral." }
if ($e.asset_pipeline.automatic_conversion -ne $true) { throw "Engine automatic conversion is disabled." }
if (-not $e.asset_pipeline.runtime_asset_strategy) { throw "Engine runtime asset strategy is missing." }
if ($e.asset_pipeline.runtime_asset_strategy.scene_containers[0] -ne ".gltf" -or $e.asset_pipeline.runtime_asset_strategy.scene_containers[1] -ne ".glb") {
    throw "Engine glTF/GLB runtime strategy is incomplete."
}
if ($e.asset_pipeline.runtime_asset_strategy.three_d_textures[0] -ne ".ktx2") { throw "Engine KTX2 runtime strategy is incomplete." }
if ($e.asset_pipeline.runtime_asset_strategy.two_d_visuals[0] -ne ".avif") { throw "Engine AVIF runtime strategy is incomplete." }

Write-Host "PASS: Sharnou-IDE accepts any source format at the intake boundary."
Write-Host "PASS: SharnouEngine performs automatic conversion/validation."
Write-Host "PASS: glTF/GLB = 3D containers; KTX2 = 3D textures; AVIF = shipped raster/2D visuals."
exit 0
