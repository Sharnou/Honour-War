param(
    [Parameter(Mandatory=$true)][string]$Source,
    [Parameter(Mandatory=$true)][string]$Output
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "SPP source file not found: $Source"
}

$commands = New-Object System.Collections.Generic.List[object]
$lineNumber = 0

foreach ($rawLine in Get-Content -LiteralPath $Source) {
    $lineNumber++
    $line = $rawLine.Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("//")) { continue }

    $tokens = [regex]::Matches($line, '"([^"]*)"|\S+') | ForEach-Object {
        if ($_.Groups[1].Success) { $_.Groups[1].Value } else { $_.Value }
    }

    $op = $tokens[0]
    switch ($op) {
        "actor_spawn" {
            if ($tokens.Count -ne 2) { throw "Line $lineNumber: actor_spawn requires an actor id." }
            $commands.Add([ordered]@{ op = "actor_spawn"; actor = $tokens[1]; line = $lineNumber })
        }
        "set_pos" {
            if ($tokens.Count -ne 4) { throw "Line $lineNumber: set_pos requires x y z." }
            [float]$x = 0; [float]$y = 0; [float]$z = 0
            if (-not [float]::TryParse($tokens[1], [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$x)) { throw "Line $lineNumber: invalid x." }
            if (-not [float]::TryParse($tokens[2], [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$y)) { throw "Line $lineNumber: invalid y." }
            if (-not [float]::TryParse($tokens[3], [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$z)) { throw "Line $lineNumber: invalid z." }
            $commands.Add([ordered]@{ op = "set_pos"; x = $x; y = $y; z = $z; line = $lineNumber })
        }
        "bind_mesh" {
            if ($tokens.Count -ne 2) { throw "Line $lineNumber: bind_mesh requires a mesh id." }
            $commands.Add([ordered]@{ op = "bind_mesh"; mesh = $tokens[1]; line = $lineNumber })
        }
        "texture_avif" {
            if ($tokens.Count -ne 2) { throw "Line $lineNumber: texture_avif requires an AVIF path." }
            if ([System.IO.Path]::GetExtension($tokens[1]).ToLowerInvariant() -ne ".avif") {
                throw "Line $lineNumber: texture_avif only accepts .avif assets."
            }
            $commands.Add([ordered]@{ op = "texture_avif"; asset = $tokens[1]; line = $lineNumber })
        }
        default {
            throw "Line $lineNumber: unknown SPP operation '$op'."
        }
    }
}

$document = [ordered]@{
    schema = "sharnou-bytecode/1"
    ide_id = "Sharnou-IDE"
    engine_id = "SharnouEngine"
    project_id = "honour-war"
    source = [System.IO.Path]::GetFullPath($Source)
    commands = @($commands)
}

$outputDirectory = Split-Path -Parent $Output
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$document | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Output -Encoding UTF8
Write-Host "PASS: SPP compiled $($commands.Count) commands -> $Output"
