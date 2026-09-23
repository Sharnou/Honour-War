param(
    [string]$UnrealRoot = $env:UNREAL_ENGINE_ROOT,
    [string]$Configuration = "Shipping",
    [switch]$Package
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($UnrealRoot)) {
    $UnrealRoot = "C:\Program Files\Epic Games\UE_5.8"
}

$Root = Split-Path -Parent $PSScriptRoot
$Project = Join-Path $Root "HonourWar.uproject"
$Ubt = Join-Path $UnrealRoot "Engine\Build\BatchFiles\Build.bat"
$Uat = Join-Path $UnrealRoot "Engine\Build\BatchFiles\RunUAT.bat"

if (!(Test-Path $Project)) { throw "HonourWar.uproject was not found." }
if (!(Test-Path $Ubt)) { throw "Unreal Engine 5.8 Build.bat was not found at $Ubt" }

Push-Location $Root
try {
    python tools\unreal_engine_contract_qa.py
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & $Ubt HonourWar Win64 $Configuration "$Project" -NoHotReloadFromIDE
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    if ($Package) {
        if (!(Test-Path $Uat)) { throw "Unreal Engine 5.8 RunUAT.bat was not found at $Uat" }
        $Archive = Join-Path $Root "Build\Windows\HonourWar"
        New-Item -ItemType Directory -Force -Path $Archive | Out-Null
        & $Uat BuildCookRun "-project=$Project" "-noP4" "-platform=Win64" "-clientconfig=$Configuration" "-build" "-cook" "-stage" "-pak" "-archive" "-archivedirectory=$Archive" "-prereqs"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
}
finally {
    Pop-Location
}
