param(
    [string]$Python = "python",
    [switch]$RunSelfTest
)

$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repo "SharnouEngine.py"
$runtime = Join-Path $repo "Build\Runtime"
$exe = Join-Path $runtime "SharnouEngine.exe"

if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "SharnouEngine.py is missing: $source"
}

$sourceText = Get-Content -LiteralPath $source -Raw
foreach ($required in @(
    "has_batch_inputs",
    "--scene",
    "--ktx2",
    "--avif",
    "texture_ktx2",
    "scene_gltf"
)) {
    if ($sourceText.IndexOf($required, [StringComparison]::Ordinal) -lt 0) {
        throw "Local SharnouEngine.py is missing required runtime parser contract: $required"
    }
}

New-Item -ItemType Directory -Force -Path $runtime | Out-Null

Write-Host "SHARNOU BUILD: source=$source"
Write-Host "SHARNOU BUILD: output=$exe"

& $Python -m PyInstaller --noconfirm --clean --onefile --console --name SharnouEngine --distpath $runtime $source
if ($LASTEXITCODE -ne 0) {
    throw "PyInstaller failed with exit code $LASTEXITCODE."
}

if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    throw "Expected executable was not produced: $exe"
}

Write-Host "SHARNOU BUILD: PASS $exe"

if ($RunSelfTest) {
    & $exe --self-test
    if ($LASTEXITCODE -ne 0) {
        throw "SharnouEngine self-test failed with exit code $LASTEXITCODE."
    }
    Write-Host "SHARNOU BUILD: self-test PASS"
}
