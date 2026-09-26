param(
    [Parameter(Mandatory=$true)][string]$Source,
    [Parameter(Mandatory=$true)][string]$Output
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "SPP source file not found: $Source"
}

$commands = [System.Collections.Generic.List[object]]::new()
$lineNumber = 0

foreach ($rawLine in Get-Content -LiteralPath $Source) {
    $lineNumber++
    $line = $rawLine.Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("//")) { continue }

    $tokenMatches = [regex]::Matches($line, '"([^"]*)"|\S+')
    $tokens = @($tokenMatches | ForEach-Object {
        if ($_.Groups[1].Success) { $_.Groups[1].Value } else { $_.Value }
    })

    if ($tokens.Count -eq 0) { continue }
    $op = [string]$tokens[0]

    switch ($op) {
        "actor_spawn" {
            if ($tokens.Count -ne 2) { throw "Line ${lineNumber}: actor_spawn requires an actor id." }
            $commands.Add([pscustomobject]@{
                op = "actor_spawn"
                actor = [string]$tokens[1]
                line = $lineNumber
            })
        }
        "set_pos" {
            if ($tokens.Count -ne 4) { throw "Line ${lineNumber}: set_pos requires x y z." }
            [float]$x = 0; [float]$y = 0; [float]$z = 0
            if (-not [float]::TryParse([string]$tokens[1], [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$x)) { throw "Line ${lineNumber}: invalid x." }
            if (-not [float]::TryParse([string]$tokens[2], [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$y)) { throw "Line ${lineNumber}: invalid y." }
            if (-not [float]::TryParse([string]$tokens[3], [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$z)) { throw "Line ${lineNumber}: invalid z." }
            $commands.Add([pscustomobject]@{
                op = "set_pos"
                x = $x
                y = $y
                z = $z
                line = $lineNumber
            })
        }
        "bind_mesh" {
            if ($tokens.Count -ne 2) { throw "Line ${lineNumber}: bind_mesh requires a mesh id." }
            $commands.Add([pscustomobject]@{
                op = "bind_mesh"
                mesh = [string]$tokens[1]
                line = $lineNumber
            })
        }
        "texture_avif" {
            if ($tokens.Count -ne 2) { throw "Line ${lineNumber}: texture_avif requires an AVIF path." }
            $asset = [string]$tokens[1]
            if ([System.IO.Path]::GetExtension($asset).ToLowerInvariant() -ne ".avif") {
                throw "Line ${lineNumber}: texture_avif only accepts .avif assets."
            }
            $commands.Add([pscustomobject]@{
                op = "texture_avif"
                asset = $asset
                line = $lineNumber
            })
        }
        "texture_ktx2" {
            if ($tokens.Count -ne 2) { throw "Line ${lineNumber}: texture_ktx2 requires a KTX2 path." }
            $asset = [string]$tokens[1]
            if ([System.IO.Path]::GetExtension($asset).ToLowerInvariant() -ne ".ktx2") {
                throw "Line ${lineNumber}: texture_ktx2 only accepts .ktx2 assets."
            }
            $commands.Add([pscustomobject]@{
                op = "texture_ktx2"
                asset = $asset
                line = $lineNumber
            })
        }
        "scene_gltf" {
            if ($tokens.Count -ne 2) { throw "Line ${lineNumber}: scene_gltf requires a .gltf or .glb path." }
            $asset = [string]$tokens[1]
            $ext = [System.IO.Path]::GetExtension($asset).ToLowerInvariant()
            if ($ext -notin @(".gltf",".glb")) {
                throw "Line ${lineNumber}: scene_gltf only accepts .gltf or .glb assets."
            }
            $commands.Add([pscustomobject]@{
                op = "scene_gltf"
                asset = $asset
                line = $lineNumber
            })
        }
        default {
            throw "Line ${lineNumber}: unknown SPP operation '$op'."
        }
    }
}

$document = [pscustomobject]@{
    schema = "sharnou-bytecode/1"
    ide_id = "Sharnou-IDE"
    engine_id = "SharnouEngine"
    project_id = "honour-war"
    source = [System.IO.Path]::GetFullPath($Source)
    commands = @($commands.ToArray())
}

$outputDirectory = Split-Path -Parent $Output
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$jsonText = $document | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($Output, $jsonText, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "PASS: SPP compiled $($commands.Count) commands -> $Output"
