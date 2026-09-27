$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".."))
$scanRoots = @(
  (Join-Path $root "Content"),
  (Join-Path $root "assets")
) | Where-Object { Test-Path -LiteralPath $_ }

$approvedRaster = @(".avif")
$rejectedRaster = @(".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".tga", ".dds")
$rejectedContainers = @(".gltf", ".glb", ".ktx2")
$authoringInterchangeRoots = @(
  (Join-Path $root "assets/3d/neural4d/incoming"),
  (Join-Path $root "Content/HonourWarArt")
)
$violations = New-Object System.Collections.Generic.List[string]

foreach($scanRoot in $scanRoots){
  Get-ChildItem -LiteralPath $scanRoot -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $path = $_.FullName
    $ext = $_.Extension.ToLowerInvariant()
    $isLegacy = $path -match "[\\/]Legacy[\\/]"
    $isAuthoringInterchange = $false
    foreach($authoringRoot in $authoringInterchangeRoots){
      if($path.StartsWith([IO.Path]::GetFullPath($authoringRoot) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)){
        $isAuthoringInterchange = $true
        break
      }
    }

    if($rejectedContainers -contains $ext -and -not $isLegacy){
      $violations.Add("REJECTED ACTIVE FORMAT: $path")
      return
    }

    if($rejectedRaster -contains $ext -and -not $isLegacy){
      $violations.Add("REJECTED RASTER FORMAT: $path")
      return
    }

    if($isAuthoringInterchange -and $ext -in @(".fbx",".obj")){
      return
    }

    if(($path -match "[\\/]assets[\\/]visual[\\/]|[\\/]assets[\\/]ui[\\/]|[\\/]Content[\\/]visual[\\/]|[\\/]Content[\\/]ui[\\/]") -and $ext -ne ".avif"){
      $violations.Add("RUNTIME VISUAL MUST BE AVIF: $path")
    }
  }
}

if($violations.Count -gt 0){
  $violations | ForEach-Object { Write-Host $_ }
  Write-Host "FAIL: active Honour War visual delivery is AVIF-only; GLTF/GLB/KTX2 are rejected."
  exit 1
}
Write-Host "PASS: AVIF-only visual delivery is enforced; GLTF/GLB/KTX2 are rejected."
exit 0
