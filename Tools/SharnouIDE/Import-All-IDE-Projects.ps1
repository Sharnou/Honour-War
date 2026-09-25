param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$Output = ".sharnou/imported-ide-projects.json"
)
$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath($ProjectRoot)
$outPath = [IO.Path]::GetFullPath((Join-Path $root $Output))

$patterns = @("*.sln", "*.slnx", "*.vcxproj", "*.vcxproj.filters", "*.code-workspace", "*.project", "*.cproject", "*.classpath", "*.iml", "*.xcodeproj", "*.xcworkspace")
$items = New-Object System.Collections.Generic.List[object]
foreach($pattern in $patterns){
    Get-ChildItem -LiteralPath $root -Recurse -Force -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like $pattern -and $_.FullName -notmatch "[\\/]\.git[\\/]" -and $_.FullName -notmatch "[\\/]\.sharnou[\\/]" } |
        ForEach-Object {
            $items.Add([ordered]@{
                source = $_.FullName.Substring($root.Length).TrimStart('\\','/')
                source_type = $_.Extension.ToLowerInvariant()
                action = "metadata-import"
                execution = "rejected"
                target = "Sharnou-IDE SPP"
            })
        }
}

$doc = [ordered]@{
    schema = "sharnou-ide-migration/2"
    project_id = "honour-war"
    canonical_ide = "Sharnou-IDE"
    canonical_engine = "SharnouEngine"
    automatic_conversion = $true
    legacy_ide_execution = $false
    external_tool_downloads = $false
    compiler_or_sdk_bootstrap = $false
    imported_projects = @($items | Sort-Object source -Unique)
    conversion_target = "Sharnou-IDE SPP"
    visual_asset_policy = [ordered]@{
        image_texture_format = ".AVIF"
        rejected_visual_formats = @(".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".tga", ".dds")
    }
}
New-Item -ItemType Directory -Force -Path (Split-Path $outPath) | Out-Null
$doc | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $outPath -Encoding utf8
Write-Host "PASS: legacy IDE metadata converted to Sharnou-IDE SPP: $outPath"
Write-Host ("Imported IDE metadata entries: " + $items.Count)
