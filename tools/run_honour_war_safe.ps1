$ErrorActionPreference = 'Continue'
Set-Location (Join-Path $PSScriptRoot '..')

$godot = Get-Command godot -ErrorAction SilentlyContinue
if ($null -eq $godot) {
    Write-Host 'Godot was not found in PATH.' -ForegroundColor Red
    Write-Host 'Install Godot 4.2.2 and add it to PATH, or launch the project from the Godot editor.'
    exit 1
}

Write-Host 'HONOUR WAR - HD SAFE LAUNCHER' -ForegroundColor Cyan
Write-Host 'Attempting Forward+ Vulkan first.'
Write-Host 'If Windows has no compatible Vulkan ICD, Compatibility/OpenGL will be used.'

& $godot.Source --path . --rendering-method forward_plus --rendering-driver vulkan @args
$forwardStatus = $LASTEXITCODE
if ($forwardStatus -eq 0) {
    exit 0
}

Write-Host ''
Write-Host 'Forward+ could not initialize Vulkan on this machine.' -ForegroundColor Yellow
Write-Host 'Falling back to Godot Compatibility/OpenGL.' -ForegroundColor Yellow
& $godot.Source --path . --rendering-method gl_compatibility --rendering-driver opengl3 @args
exit $LASTEXITCODE
