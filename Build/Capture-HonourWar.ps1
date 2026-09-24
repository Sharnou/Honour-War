param(
    [int]$TimeoutSeconds = 30
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$PackageRoot = Join-Path $Root "Build\Windows\HonourWar"
$Exe = Get-ChildItem -Path $PackageRoot -Recurse -Filter "HonourWar.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($null -eq $Exe) { throw "HonourWar.exe was not found under $PackageRoot. Build/package the game first." }

$Process = Start-Process -FilePath $Exe.FullName -ArgumentList @(
    "-HonourWarCapture", "-HonourWarE2E", "-windowed", "-ResX=1920", "-ResY=1080", "-Unattended", "-NoSplash"
) -PassThru

if (-not $Process.WaitForExit($TimeoutSeconds * 1000)) {
    $Process.Kill()
    throw "Honour War capture process exceeded timeout."
}

if ($Process.ExitCode -ne 0) {
    throw "HonourWar.exe exited with code $($Process.ExitCode), so the real runtime test failed."
}

$RuntimeLog = Get-ChildItem -Path $PackageRoot -Recurse -Filter "HonourWar.log" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $RuntimeLog) {
    throw "Honour War runtime log was not produced."
}
$RuntimeLogCopy = Join-Path $Root "Build\HonourWar-runtime-log.txt"
Copy-Item $RuntimeLog.FullName $RuntimeLogCopy -Force
$LogText = Get-Content $RuntimeLog.FullName -Raw
$FatalMarkers = @("Fatal error","Unhandled Exception","Assertion failed","Ensure condition failed","Critical error")
$FatalHits = @($FatalMarkers | Where-Object { $LogText -match [regex]::Escape($_) })
if ($FatalHits.Count -gt 0) {
    throw "Honour War runtime log contains fatal markers: $($FatalHits -join ', '). See $RuntimeLogCopy"
}

$Screenshot = Get-ChildItem -Path $PackageRoot -Recurse -Filter "HonourWar-real-runtime.png" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $Screenshot) { throw "Real Unreal runtime screenshot was not produced." }

python (Join-Path $Root "tools\unreal_runtime_screenshot_qa.py") $Screenshot.FullName
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Copy-Item $Screenshot.FullName (Join-Path $Root "Build\HonourWar-real-runtime.png") -Force

$E2EReport = Join-Path $Root "Saved\HonourWar-E2E-report.txt"
if (-not (Test-Path $E2EReport)) { throw "Honour War runtime E2E report was not produced." }
Copy-Item $E2EReport (Join-Path $Root "Build\HonourWar-E2E-report.txt") -Force

Write-Host "REAL_UNREAL_EXE_SCREENSHOT_PASS: $($Screenshot.FullName)"
Write-Host "REAL_UNREAL_E2E_REPORT_PASS: $E2EReport"
