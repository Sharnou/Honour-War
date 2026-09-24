param(
    [int]$TimeoutSeconds = 30
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$PackageRoot = Join-Path $Root "Build\Windows\HonourWar"
$Exe = Get-ChildItem -Path $PackageRoot -Recurse -Filter "HonourWar.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($null -eq $Exe) { throw "HonourWar.exe was not found under $PackageRoot. Build/package the game first." }

$CaptureOutput = Join-Path $PackageRoot "Saved\Screenshots\HonourWar-real-runtime.png"
$CaptureReport = Join-Path $PackageRoot "Saved\HonourWar-E2E-report.txt"
$CaptureLog = Join-Path $PackageRoot "Saved\Logs\HonourWar.log"
foreach ($OldFile in @($CaptureOutput, $CaptureReport, $CaptureLog)) {
    if (Test-Path $OldFile) { Remove-Item $OldFile -Force -ErrorAction SilentlyContinue }
}
foreach ($OldBuildFile in @(
    (Join-Path $Root "Build\HonourWar-real-runtime.png"),
    (Join-Path $Root "Build\HonourWar-E2E-report.txt"),
    (Join-Path $Root "Build\HonourWar-runtime-log.txt")
)) {
    if (Test-Path $OldBuildFile) { Remove-Item $OldBuildFile -Force -ErrorAction SilentlyContinue }
}

$Process = Start-Process -FilePath $Exe.FullName -ArgumentList @(
    "-HonourWarCapture", "-HonourWarE2E", "-windowed", "-ResX=1920", "-ResY=1080", "-Unattended", "-NoSplash"
) -WorkingDirectory $PackageRoot -PassThru

$TimedOut = -not $Process.WaitForExit($TimeoutSeconds * 1000)
if ($TimedOut) {
    try { $Process.Kill() } catch {}
}

$RuntimeLog = Get-ChildItem -Path $PackageRoot -Recurse -Filter "HonourWar.log" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -ne $RuntimeLog) {
    $RuntimeLogCopy = Join-Path $Root "Build\HonourWar-runtime-log.txt"
    Copy-Item $RuntimeLog.FullName $RuntimeLogCopy -Force
    $LogText = Get-Content $RuntimeLog.FullName -Raw
    $FatalMarkers = @("Fatal error","Unhandled Exception","Assertion failed","Ensure condition failed","Critical error")
    $FatalHits = @($FatalMarkers | Where-Object { $LogText -match [regex]::Escape($_) })
    if ($FatalHits.Count -gt 0) {
        throw "Honour War runtime log contains fatal markers: $($FatalHits -join ', '). See $RuntimeLogCopy"
    }
}

$E2EReport = Get-ChildItem -Path $PackageRoot -Recurse -Filter "HonourWar-E2E-report.txt" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -ne $E2EReport) {
    Copy-Item $E2EReport.FullName (Join-Path $Root "Build\HonourWar-E2E-report.txt") -Force
}

if ($TimedOut) {
    throw "Honour War capture process exceeded timeout."
}

if ($Process.ExitCode -ne 0) {
    throw "HonourWar.exe exited with code $($Process.ExitCode), so the real runtime test failed. Diagnostics were copied when produced."
}

$Screenshot = Get-ChildItem -Path $PackageRoot -Recurse -Filter "HonourWar-real-runtime.png" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $Screenshot) { throw "Real Unreal runtime screenshot was not produced." }

python (Join-Path $Root "tools\unreal_runtime_screenshot_qa.py") $Screenshot.FullName
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Copy-Item $Screenshot.FullName (Join-Path $Root "Build\HonourWar-real-runtime.png") -Force

if (-not (Test-Path (Join-Path $Root "Build\HonourWar-E2E-report.txt"))) {
    throw "Honour War runtime E2E report was not produced."
}

Write-Host "REAL_UNREAL_EXE_SCREENSHOT_PASS: $($Screenshot.FullName)"
Write-Host "REAL_UNREAL_E2E_REPORT_PASS: $E2EReport"
