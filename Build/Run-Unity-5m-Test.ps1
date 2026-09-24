param([int]$TimeoutSeconds=360)
$ErrorActionPreference='Stop'

# Honour War engine lock — do not change without an explicit project-engine migration.
$RequiredUnityEditor = '6000.0.71f1'
$RequiredUnityHub = '3.21.3'

$project=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\Unity'))
$roots=@('C:\Program Files\Unity\Hub\Editor',(Join-Path $env:LOCALAPPDATA 'Programs\Unity Hub\Editor'))
$unity=$null
foreach($root in $roots){
    if(Test-Path $root){
        $candidate=Join-Path $root $RequiredUnityEditor 'Editor\Unity.exe'
        if(Test-Path $candidate){$unity=$candidate;break}
    }
}
if(-not $unity){throw "Required Unity Editor $RequiredUnityEditor was not found. Honour War is permanently pinned to this Editor version."}

$out=Join-Path $PSScriptRoot 'Unity\HonourWar.exe'
& $unity -batchmode -nographics -quit -projectPath $project -buildTarget Win64 -executeMethod HonourWar.EditorTools.HonourWarBuild.BuildWindows -logFile (Join-Path $PSScriptRoot 'Unity-5m-build.log')
if($LASTEXITCODE -ne 0){throw "Unity $RequiredUnityEditor build failed: $LASTEXITCODE"}
if(-not(Test-Path $out)){throw 'Unity executable was not produced.'}

$proc=Start-Process -FilePath $out -ArgumentList '-honourwar-runtime-test' -PassThru
if(-not $proc.WaitForExit($TimeoutSeconds*1000)){
    Stop-Process -Id $proc.Id -Force
    throw '5-minute Unity runtime test timed out.'
}
if($proc.ExitCode -ne 0){throw "Unity runtime exited with code $($proc.ExitCode)."}
Write-Host "HONOUR_WAR_UNITY_5M_RUNTIME_PASS editor=$RequiredUnityEditor hub=$RequiredUnityHub"
