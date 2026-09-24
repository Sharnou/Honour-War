param(
    [int]$TimeoutSeconds = 3720
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$PackageRoot = Join-Path $Root "Build\Windows\HonourWar"
$Exe = Get-ChildItem -Path $PackageRoot -Recurse -Filter "HonourWar.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($null -eq $Exe) { throw "HonourWar.exe was not found under $PackageRoot. Build/package the game first." }

$ReportCopy = Join-Path $Root "Build\HonourWar-1h-soak-report.txt"
$LogCopy = Join-Path $Root "Build\HonourWar-1h-runtime-log.txt"
$ErrorsCopy = Join-Path $Root "Build\HonourWar-1h-soak-errors.txt"

foreach ($File in @($ReportCopy,$LogCopy,$ErrorsCopy)) {
    if (Test-Path $File) { Remove-Item $File -Force -ErrorAction SilentlyContinue }
}

$OldFiles = @(
    (Join-Path $PackageRoot "Saved\HonourWar-1h-soak-report.txt"),
    (Join-Path $PackageRoot "Saved\Logs\HonourWar.log")
)
foreach ($File in $OldFiles) {
    if (Test-Path $File) { Remove-Item $File -Force -ErrorAction SilentlyContinue }
}

$Process = Start-Process -FilePath $Exe.FullName -WorkingDirectory $PackageRoot -ArgumentList @(
    "-HonourWarCapture", "-HonourWarE2E", "-HonourWarSoak",
    "-windowed", "-ResX=1920", "-ResY=1080", "-Unattended", "-NoSplash"
) -PassThru

$TimedOut = -not $Process.WaitForExit($TimeoutSeconds * 1000)
if ($TimedOut) {
    try { $Process.Kill() } catch {}
}

$RuntimeLog = Get-ChildItem -Path $PackageRoot -Recurse -Filter "HonourWar.log" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $RuntimeLog) {
    throw "Honour War runtime log was not produced."
}
Copy-Item $RuntimeLog.FullName $LogCopy -Force
$LogText = Get-Content $RuntimeLog.FullName -Raw

$Report = Get-ChildItem -Path $PackageRoot -Recurse -Filter "HonourWar-1h-soak-report.txt" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -ne $Report) {
    Copy-Item $Report.FullName $ReportCopy -Force
}

$FatalMarkers = @("Fatal error","Unhandled Exception","Assertion failed","Ensure condition failed","Critical error")
$FatalHits = @($FatalMarkers | Where-Object { $LogText -match [regex]::Escape($_) })
$LogLines = @(Get-Content $RuntimeLog.FullName)

$ErrorLines = @(
    Get-Content $RuntimeLog.FullName |
    Where-Object {
        $_ -match "Error:" -or
        $_ -match "Ensure condition failed" -or
        $_ -match "Fatal error" -or
        $_ -match "Unhandled Exception" -or
        $_ -match "Critical error"
    }
) | Select-Object -Unique
$CrashLines = @($LogLines | Where-Object {
    $_ -match "Fatal error" -or $_ -match "Unhandled Exception" -or
    $_ -match "Assertion failed" -or $_ -match "Ensure condition failed" -or $_ -match "Critical error"
}) | Select-Object -Unique
$UnrealErrorLines = @($LogLines | Where-Object {
    $_ -match "Error:" -or $_ -match "Ensure condition failed" -or $_ -match "Assertion failed"
}) | Select-Object -Unique
$ClassFailureLines = @($SoakText -split "\r?\n" | Where-Object { $_ -match "FAIL\[CLASS(-END)?\]" }) | Select-Object -Unique
$MovementFailureLines = @($SoakText -split "\r?\n" | Where-Object { $_ -match "FAIL\[MOVEMENT\]" }) | Select-Object -Unique
$SkillFailureLines = @($SoakText -split "\r?\n" | Where-Object { $_ -match "FAIL\[SKILL\]" }) | Select-Object -Unique
$RuntimeHarnessFailureLines = @($SoakText -split "\r?\n" | Where-Object { $_ -match "FAIL\[(BOOT|RUNTIME)\]" }) | Select-Object -Unique

@(
    "Honour War One-Hour Runtime Diagnostic Classification"
    "IMPORTANT: static contract QA is not gameplay evidence; this file classifies the real packaged runtime log/report."
    "CRASH_OR_ASSERT_COUNT=$($CrashLines.Count)"
    "UNREAL_ERROR_LINE_COUNT=$($UnrealErrorLines.Count)"
    "CLASS_FAILURE_COUNT=$($ClassFailureLines.Count)"
    "MOVEMENT_FAILURE_COUNT=$($MovementFailureLines.Count)"
    "SKILL_FAILURE_COUNT=$($SkillFailureLines.Count)"
    "RUNTIME_HARNESS_FAILURE_COUNT=$($RuntimeHarnessFailureLines.Count)"
    ""
    "[CRASH_OR_ASSERT]"; $CrashLines
    ""
    "[UNREAL_ERROR]"; $UnrealErrorLines
    ""
    "[CLASS_FAILURE]"; $ClassFailureLines
    ""
    "[MOVEMENT_FAILURE]"; $MovementFailureLines
    ""
    "[SKILL_FAILURE]"; $SkillFailureLines
    ""
    "[RUNTIME_HARNESS_FAILURE]"; $RuntimeHarnessFailureLines
) | Set-Content -Path $ErrorsCopy -Encoding UTF8

if ($TimedOut) {
    throw "Honour War one-hour soak exceeded the $TimeoutSeconds seconds safety timeout."
}
if ($Process.ExitCode -ne 0) {
    throw "HonourWar.exe exited with code $($Process.ExitCode). See $LogCopy and $ReportCopy."
}
if ($null -eq $Report) {
    throw "One-hour soak report was not produced. This is a runtime-harness failure, not static validation."
}

$SoakText = Get-Content $ReportCopy -Raw
$ClassPasses = [regex]::Matches($SoakText,"PASS\[CLASS\]").Count
$ClassEnds = [regex]::Matches($SoakText,"PASS\[CLASS-END\]").Count

if ($SoakText -match "FAIL") {
    throw "One-hour soak report contains FAIL entries. See $ReportCopy and $ErrorsCopy."
}
if ($ClassPasses -lt 7 -or $ClassEnds -lt 7) {
    throw "One-hour soak did not complete all seven class phases. class entries=$ClassPasses class-end entries=$ClassEnds"
}
if ($SoakText -notmatch "PASS\[END\]") {
    throw "One-hour soak did not record a PASS[END] completion marker."
}
if ($FatalHits.Count -gt 0) {
    throw "Unreal runtime log contains fatal markers: $($FatalHits -join ', '). See $LogCopy."
}

Write-Host "HONOUR_WAR_1H_SOAK_PASS: seven classes exercised for a full 60-minute runtime session."
Write-Host "HONOUR_WAR_1H_SOAK_REPORT: $ReportCopy"
Write-Host "HONOUR_WAR_1H_SOAK_LOG: $LogCopy"
Write-Host "HONOUR_WAR_1H_SOAK_ERRORS: $ErrorsCopy"
