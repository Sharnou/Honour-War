$ErrorActionPreference = "Stop"

$root = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".."))
$violations = New-Object System.Collections.Generic.List[string]

$forbiddenFileNames = @(
    "CMakeLists.txt",
    "CMakePresets.json",
    "vcpkg.json",
    "Directory.Build.props",
    "Directory.Build.targets",
    "*.sln",
    "*.slnx",
    "*.vcxproj",
    "*.vcxproj.filters"
)

foreach ($pattern in $forbiddenFileNames) {
    Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch "[\\/]Legacy[\\/]" -and $_.Name -like $pattern
        } |
        ForEach-Object { $violations.Add("FORBIDDEN ACTIVE BUILD FILE: " + $_.FullName) }
}

$codeExtensions = @(".ps1",".cmd",".bat",".yml",".yaml",".cpp",".c",".cc",".h",".hpp",".ixx")
$forbiddenText = @(
    "(?i)\bmsbuild(\.exe)?\b",
    "(?i)\bdevenv(\.exe)?\b",
    "(?i)\bvcvars(\w*)?(\.bat)?\b",
    "(?i)\bcl(\.exe)?\s+",
    "(?i)\bvswhere(\.exe)?\b",
    "(?i)\bvcpkg(\.exe)?\b",
    "(?i)\bcmake(\.exe)?\b",
    "(?i)\bUnity(\.exe)?\b",
    "(?i)\bUnrealBuildTool(\.exe)?\b",
    "(?i)\bVisual Studio\b"
)

Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notmatch "[\\/]Legacy[\\/]" -and
        $codeExtensions -contains $_.Extension.ToLowerInvariant() -and
        $_.FullName -notmatch "[\\/]docs[\\/]"
    } |
    ForEach-Object {
        $path = $_.FullName
        $content = Get-Content -LiteralPath $path -Raw -ErrorAction Stop
        foreach ($pattern in $forbiddenText) {
            if ($content -match $pattern) {
                $violations.Add("FORBIDDEN TOOLCHAIN REFERENCE: $path -> $pattern")
            }
        }
    }

if ($violations.Count -gt 0) {
    $violations | ForEach-Object { Write-Host $_ }
    Write-Host "FAIL: Sharnou IDE toolchain policy rejected active Microsoft/Unity/Unreal/CMake/vcpkg build dependencies."
    exit 1
}

Write-Host "PASS: Sharnou IDE toolchain policy."
Write-Host "PASS: No active Microsoft IDE/build/SDK toolchain invocation detected."
Write-Host "PASS: No active CMake/vcpkg/Unity/Unreal project build files detected."
exit 0
