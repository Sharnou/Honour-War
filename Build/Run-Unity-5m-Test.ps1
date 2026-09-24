param([int]$TimeoutSeconds=360)
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\Unity'))
$roots=@('C:\Program Files\Unity\Hub\Editor',(Join-Path $env:LOCALAPPDATA 'Programs\Unity Hub\Editor'))
$unity=$null
foreach($root in $roots){if(Test-Path $root){$unity=Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | Where-Object {$_.Name -like '6000.0.*'} | Sort-Object Name -Descending | ForEach-Object {Join-Path $_.FullName 'Editor\Unity.exe'} | Where-Object {Test-Path $_} | Select-Object -First 1;if($unity){break}}}
if(-not $unity){throw 'Unity 6.0 LTS (6000.0.x) was not found.'}
$out=Join-Path $PSScriptRoot 'Unity\HonourWar.exe'
& $unity -batchmode -nographics -quit -projectPath $project -buildTarget Win64 -executeMethod HonourWar.EditorTools.HonourWarBuild.BuildWindows -logFile (Join-Path $PSScriptRoot 'Unity-5m-build.log')
if($LASTEXITCODE -ne 0){throw "Unity build failed: $LASTEXITCODE"}
if(-not(Test-Path $out)){throw 'Unity executable was not produced.'}
$proc=Start-Process -FilePath $out -ArgumentList '-honourwar-runtime-test' -PassThru
if(-not $proc.WaitForExit($TimeoutSeconds*1000)){Stop-Process -Id $proc.Id -Force;throw '5-minute Unity runtime test timed out.'}
if($proc.ExitCode -ne 0){throw "Unity runtime exited with code $($proc.ExitCode)."}
Write-Host 'HONOUR_WAR_UNITY_5M_RUNTIME_PASS'