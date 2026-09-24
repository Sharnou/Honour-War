param(
    [switch]$Build,
    [switch]$OpenEditor
)

$ErrorActionPreference = 'Stop'
$project = Join-Path $PSScriptRoot '..\Unity'
$project = [IO.Path]::GetFullPath($project)
$roots = @(
    'C:\Program Files\Unity\Hub\Editor',
    (Join-Path $env:LOCALAPPDATA 'Programs\Unity Hub\Editor')
)
$unity = $null
foreach ($root in $roots) {
    if (Test-Path $root) {
        $candidate = Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like '6000.0.*' } |
            Sort-Object Name -Descending |
            ForEach-Object { Join-Path $_.FullName 'Editor\Unity.exe' } |
            Where-Object { Test-Path $_ } |
            Select-Object -First 1
        if ($candidate) { $unity = $candidate; break }
    }
}
if (-not $unity) { throw 'Unity 6.0 LTS Editor (6000.0.x) was not found. Install it through Unity Hub first.' }

Write-Host "UNITY_EDITOR=$unity"
Write-Host "UNITY_PROJECT=$project"

if ($OpenEditor) {
    Start-Process -FilePath $unity -ArgumentList @('-projectPath', $project)
    exit 0
}

if ($Build) {
    $out = Join-Path $PSScriptRoot 'Unity\HonourWar.exe'
    New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null
    & $unity -batchmode -nographics -quit -projectPath $project -buildTarget Win64 -buildWindows64Player $out -logFile (Join-Path $PSScriptRoot 'Unity-build.log')
    if ($LASTEXITCODE -ne 0) { throw "Unity Windows build failed with exit code $LASTEXITCODE. See Build/Unity-build.log." }
    if (-not (Test-Path $out)) { throw 'Unity did not produce HonourWar.exe.' }
    Write-Host "UNITY_REAL_EXE_PASS=$out"
    exit 0
}

& $unity -projectPath $project
