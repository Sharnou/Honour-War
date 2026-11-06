[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $EngineRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$resolved = & (Join-Path $PSScriptRoot 'toolchain/Resolve-PinnedSharnouCompiler.ps1')
if (-not $resolved -or $resolved.ReleaseTag -ne 'R26.0-R2-R8') { throw 'Pinned compiler resolution did not return the expected release.' }

$engineRoot = [System.IO.Path]::GetFullPath($EngineRoot)
$enginePinPath = Join-Path $engineRoot 'compiler-version.json'
if (-not (Test-Path -LiteralPath $enginePinPath -PathType Leaf)) { throw "Engine compiler pin is missing: $enginePinPath" }
$enginePin = Get-Content -LiteralPath $enginePinPath -Raw | ConvertFrom-Json
if ($enginePin.release_tag -cne $resolved.ReleaseTag -or $enginePin.asset_sha256 -cne $resolved.ArchiveSha256) {
    throw 'Honour War and Sharnou Engine compiler pins do not match.'
}
$cppSources = @(Get-ChildItem -LiteralPath (Join-Path $engineRoot 'src') -Recurse -File | Where-Object { $_.Extension -in @('.cpp','.cc','.cxx','.hpp','.h') })
if ($cppSources.Count -gt 0 -and -not $resolved.NativeCppFrontend) {
    throw ("HONOUR WAR BUILD BLOCKED: the pinned compiler is verified but cannot compile the Engine's {0} C++ source/header files. The game runtime build must remain blocked until a Sharnou C++ frontend/native driver or a Sharnou-language Engine port exists." -f $cppSources.Count)
}
throw 'No Honour War native build adapter is configured for the pinned compiler release.'
