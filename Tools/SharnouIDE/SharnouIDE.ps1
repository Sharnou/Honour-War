param(
    [ValidateSet("validate","migrate","compile","self-test","runtime-test","run")]
    [string]$Command = "validate",
    [int]$RuntimeTestSeconds = 300
)

$ErrorActionPreference = "Stop"

$ideRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $ideRoot "..\.."))
$manifestPath = Join-Path $ideRoot "honour-war.spp.json"
$policyPath = Join-Path $repoRoot "ci\sharnou-stack-policy.ps1"
$avifPolicyPath = Join-Path $repoRoot "ci\sharnou-avif-policy.ps1"
$migrationPath = Join-Path $ideRoot "Import-All-IDE-Projects.ps1"
$compilerPath = Join-Path $ideRoot "Compile-Spp.ps1"
$sppSource = Join-Path $ideRoot "project\main.spp"
$programPath = Join-Path $repoRoot "Build\Runtime\honour-war.sppc.json"

if (-not (Test-Path -LiteralPath $manifestPath)) { throw "Sharnou IDE manifest missing: $manifestPath" }
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.canonical_identity.project_id -ne "honour-war" -or $manifest.canonical_identity.canonical -ne $true) { throw "Canonical Honour War identity mismatch." }
if ($manifest.ide.id -ne "Sharnou-IDE") { throw "SPP IDE identity mismatch." }
if ($manifest.engine.id -ne "SharnouEngine") { throw "SPP engine identity mismatch." }
if ($manifest.build_policy.network_downloads -ne $false) { throw "External network bootstrap is not permitted." }
if ($manifest.build_policy.external_tool_bootstrap -ne $false) { throw "External tool bootstrap is not permitted." }
if ($manifest.visual_format_policy.accepted_texture_formats.Count -ne 1 -or $manifest.visual_format_policy.accepted_texture_formats[0] -ne ".avif") { throw "Honour War visual policy is not AVIF-only." }

$engineCandidates = @()
foreach ($relative in $manifest.engine.runtime_candidates) { $engineCandidates += Join-Path $repoRoot $relative }
$enginePath = $engineCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1

if ($Command -eq "migrate") {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $migrationPath -ProjectRoot $repoRoot
    exit $LASTEXITCODE
}

if ($Command -eq "compile") {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $compilerPath -Source $sppSource -Output $programPath
    exit $LASTEXITCODE
}

if ($Command -eq "validate") {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $policyPath
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $avifPolicyPath
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "PASS: canonical project = honour-war."
    Write-Host "PASS: authoring authority = Sharnou-IDE."
    Write-Host "PASS: runtime authority = SharnouEngine."
    Write-Host "PASS: visual assets = AVIF-only."
    Write-Host "PASS: external tool download/bootstrap = disabled."
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $compilerPath -Source $sppSource -Output $programPath
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    if (-not $enginePath) {
        Write-Warning "Sharnou Engine executable not present in the local runtime candidates."
        Write-Warning "Source/project validation is complete; runtime execution requires a built SharnouEngine.exe."
        exit 0
    }
    Write-Host "PASS: Sharnou Engine runtime = $enginePath"
    exit 0
}

if (-not $enginePath) { throw "SharnouEngine.exe is not available in the configured runtime candidates." }
$env:SHARNOU_IDE_SESSION = "1"
$env:SHARNOU_IDE_REPOSITORY = "https://github.com/Sharnou/Sharnou-IDE"
$env:SHARNOU_ENGINE_ID = "SharnouEngine"
$env:SHARNOU_PROJECT_ID = "honour-war"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $compilerPath -Source $sppSource -Output $programPath
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location -LiteralPath $repoRoot
switch ($Command) {
    "self-test" { & $enginePath "--self-test"; exit $LASTEXITCODE }
    "runtime-test" { & $enginePath "--runtime-test=$RuntimeTestSeconds"; exit $LASTEXITCODE }
    "run" { & $enginePath; exit $LASTEXITCODE }
}
