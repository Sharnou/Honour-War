param(
    [ValidateSet("validate","self-test","runtime-test","run")]
    [string]$Command = "validate",
    [int]$RuntimeTestSeconds = 300
)

$ErrorActionPreference = "Stop"

$ideRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $ideRoot "..\.."))
$manifestPath = Join-Path $ideRoot "honour-war.spp.json"
$policyPath = Join-Path $repoRoot "ci\sharnou-stack-policy.ps1"

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Sharnou IDE manifest missing: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

if ($manifest.ide.id -ne "Sharnou-IDE") { throw "SPP IDE identity mismatch." }
if ($manifest.engine.id -ne "SharnouEngine") { throw "SPP engine identity mismatch." }
if ($manifest.build_policy.network_downloads -ne $false) { throw "External network bootstrap is not permitted." }
if ($manifest.build_policy.external_tool_bootstrap -ne $false) { throw "External tool bootstrap is not permitted." }

$engineCandidates = @()
foreach ($relative in $manifest.engine.runtime_candidates) {
    $engineCandidates += Join-Path $repoRoot $relative
}
$enginePath = $engineCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1

if ($Command -eq "validate") {
    if (Test-Path -LiteralPath $policyPath) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $policyPath
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    Write-Host "PASS: Sharnou IDE project contract validated."
    Write-Host "PASS: Engine identity = SharnouEngine."
    Write-Host "PASS: External tool download/bootstrap = disabled."
    if (-not $enginePath) {
        Write-Warning "Sharnou Engine executable not present in the local runtime candidates."
        Write-Warning "Source/project validation is complete; runtime execution requires a built SharnouEngine.exe."
        exit 0
    }
    Write-Host "PASS: Sharnou Engine runtime = $enginePath"
    exit 0
}

if (-not $enginePath) {
    throw "SharnouEngine.exe is not available in the configured runtime candidates."
}

switch ($Command) {
    "self-test" {
        & $enginePath "--self-test"
        exit $LASTEXITCODE
    }
    "runtime-test" {
        & $enginePath "--runtime-test=$RuntimeTestSeconds"
        exit $LASTEXITCODE
    }
    "run" {
        & $enginePath
        exit $LASTEXITCODE
    }
}
