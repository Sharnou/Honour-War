$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".."))
$assetRoot = Join-Path $root "Content"
$rejected = @(".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".tga", ".dds")
$violations = New-Object System.Collections.Generic.List[string]

if(Test-Path -LiteralPath $assetRoot){
    Get-ChildItem -LiteralPath $assetRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
      Where-Object { $rejected -contains $_.Extension.ToLowerInvariant() } |
      ForEach-Object { $violations.Add("REJECTED CONTENT VISUAL FORMAT: $($_.FullName)") }
}

if($violations.Count -gt 0){
    $violations | ForEach-Object { Write-Host $_ }
    Write-Host "FAIL: Honour War Content visual assets must use .AVIF."
    exit 1
}
Write-Host "PASS: Honour War Content visual assets are AVIF-only."
exit 0
