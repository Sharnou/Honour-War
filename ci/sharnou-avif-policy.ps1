$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".."))
$assetRoot = Join-Path $root "Content"
$assetsRoot = Join-Path $root "assets"
$rejectedRaster = @(".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".tga", ".dds")
$rejectedRuntimeModels = @(".fbx", ".obj", ".blend")
$violations = New-Object System.Collections.Generic.List[string]

foreach($rootPath in @($assetRoot,$assetsRoot)){
  if(-not (Test-Path -LiteralPath $rootPath)){ continue }
  Get-ChildItem -LiteralPath $rootPath -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $path = $_.FullName
    $ext = $_.Extension.ToLowerInvariant()
    $isSourceReference = $path -match "[\\/]Legacy[\\/]" -or $path -match "[\\/]references?[\\/]"
    if($rejectedRaster -contains $ext -and -not $isSourceReference){
      $violations.Add("REJECTED RASTER FORMAT: $path")
    }
  }
}

# Content/3D runtime models must be glTF 2.x containers.
$modelRoots = @(
  (Join-Path $assetRoot "models"),
  (Join-Path $assetsRoot "models")
)
foreach($modelRoot in $modelRoots){
  if(Test-Path -LiteralPath $modelRoot){
    Get-ChildItem -LiteralPath $modelRoot -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
      if($_.Name -match "^README\.md$"){ return }
      $ext=$_.Extension.ToLowerInvariant()
      if($rejectedRuntimeModels -contains $ext -or $ext -notin @(".gltf",".glb")){
        $violations.Add("REJECTED RUNTIME MODEL FORMAT: $($_.FullName)")
      }
    }
  }
}

# 3D material textures are KTX2; 2D/UI raster imagery is AVIF.
$textureRoots = @(
  (Join-Path $assetRoot "textures"),
  (Join-Path $assetsRoot "textures")
)
foreach($textureRoot in $textureRoots){
  if(Test-Path -LiteralPath $textureRoot){
    Get-ChildItem -LiteralPath $textureRoot -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
      if($_.Name -match "^README\.md$"){ return }
      $ext=$_.Extension.ToLowerInvariant()
      $path=$_.FullName
      if($path -match "[\\/]3d[\\/]|[\\/]materials[\\/]|[\\/]material[\\/]|[\\/]characters[\\/]|[\\/]environment[\\/]"){
        if($ext -ne ".ktx2"){ $violations.Add("3D MATERIAL TEXTURE MUST BE KTX2: $path") }
      } elseif($ext -notin @(".avif",".ktx2")){
        $violations.Add("REJECTED TEXTURE FORMAT: $path")
      }
    }
  }
}

if($violations.Count -gt 0){
  $violations | ForEach-Object { Write-Host $_ }
  Write-Host "FAIL: Honour War runtime assets must use glTF/GLB + KTX2 + AVIF by asset role."
  exit 1
}
Write-Host "PASS: glTF/GLB runtime containers, KTX2 3D textures and AVIF 2D visuals are enforced."
exit 0
