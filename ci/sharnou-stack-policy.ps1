$ErrorActionPreference = "Stop"
$root = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".."))
$violations = New-Object System.Collections.Generic.List[string]

$forbiddenFileNames = @(
    "CMakeLists.txt", "CMakePresets.json", "vcpkg.json", "Directory.Build.props", "Directory.Build.targets",
    "*.sln", "*.slnx", "*.vcxproj", "*.vcxproj.filters"
)
foreach ($pattern in $forbiddenFileNames) {
    Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "[\\/]Legacy[\\/]" -and $_.Name -like $pattern } |
        ForEach-Object { $violations.Add("FORBIDDEN ACTIVE BUILD FILE: " + $_.FullName) }
}

$codeExtensions = @(".ps1",".cmd",".bat",".cpp",".c",".cc",".h",".hpp",".ixx")
$forbiddenText = @(
    "(?i)\bmsbuild(\.exe)?\b", "(?i)\bdevenv(\.exe)?\b", "(?i)\bVisual Studio\b", "(?i)\bWindows SDK\b",
    "(?i)\bvcvars(\w*)?(\.bat)?\b", "(?i)\bcl(\.exe)?\s+", "(?i)\bvswhere(\.exe)?\b",
    "(?i)\bvcpkg(\.exe)?\b", "(?i)\bcmake(\.exe)?\b", "(?i)\bUnity(\.exe)?\b", "(?i)\bUnrealBuildTool(\.exe)?\b",
    "(?i)\bInvoke-WebRequest\b", "(?i)\bStart-BitsTransfer\b", "(?i)\bwinget\s+install\b",
    "(?i)\bchoco\s+install\b", "(?i)\bscoop\s+install\b", "(?i)\bdotnet\s+tool\s+install\b"
)
Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notmatch "[\\/]Legacy[\\/]" -and
        $_.FullName -notmatch "[\\/]\.github[\\/]workflows[\\/]" -and
        $_.FullName -notmatch "ci[\\/]sharnou-stack-policy\.ps1$" -and
        $codeExtensions -contains $_.Extension.ToLowerInvariant() -and
        $_.FullName -notmatch "[\\/]docs[\\/]"
    } |
    ForEach-Object {
        $path = $_.FullName
        $content = Get-Content -LiteralPath $path -Raw -ErrorAction Stop
        foreach ($pattern in $forbiddenText) {
            if ($content -match $pattern) { $violations.Add("FORBIDDEN TOOLCHAIN/DOWNLOAD REFERENCE: $path -> $pattern") }
        }
    }

if ($violations.Count -gt 0) {
    $violations | ForEach-Object { Write-Host $_ }
    exit 1
}
Write-Host "PASS: Sharnou IDE toolchain policy."
Write-Host "PASS: Visual Studio/MSBuild/Windows SDK/CMake/vcpkg/Unity/Unreal paths rejected."
Write-Host "PASS: External programming-tool bootstrap/download commands rejected."
exit 0