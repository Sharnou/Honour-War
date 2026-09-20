param(
    [int]$TimeoutSeconds = 30
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$PackageRoot = Join-Path $Root "Build\Windows\HonourWar"
$Exe = Get-ChildItem -Path $PackageRoot -Recurse -Filter "HonourWar.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($null -eq $Exe) { throw "HonourWar.exe was not found under $PackageRoot. Build/package the game first." }

$Process = Start-Process -FilePath $Exe.FullName -ArgumentList @(
    "-HonourWarCapture", "-windowed", "-ResX=1920", "-ResY=1080", "-Unattended", "-NoSplash"
) -PassThru

if (-not $Process.WaitForExit($TimeoutSeconds * 1000)) {
    $Process.Kill()
    throw "Honour War capture process exceeded timeout."
}

$Screenshot = Get-ChildItem -Path $PackageRoot -Recurse -Filter "HonourWar-real-runtime.png" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $Screenshot) { throw "Real Unreal runtime screenshot was not produced." }

python (Join-Path $Root "tools\unreal_runtime_screenshot_qa.py") $Screenshot.FullName
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Copy-Item $Screenshot.FullName (Join-Path $Root "Build\HonourWar-real-runtime.png") -Force
Write-Host "REAL_UNREAL_EXE_SCREENSHOT_PASS: $($Screenshot.FullName)"
