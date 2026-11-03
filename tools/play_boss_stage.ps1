param(
    [ValidateSet('count', 'prince', 'king', 'emperor')][string]$Boss = 'prince',
    [ValidateSet('ranged_single', 'melee_single', 'melee_area', 'uv_floss')][string]$Build = 'ranged_single',
    [ValidateSet('easy', 'normal', 'hard', 'hell')][string]$Difficulty = 'normal',
    [switch]$Full,
    [switch]$Trial
)
$ErrorActionPreference = 'Stop'
$repoDirectory = Split-Path -Parent $PSScriptRoot
$godotExecutable = Get-Command 'Godot_v4.7.2-stable_win64_console.exe' -ErrorAction SilentlyContinue
if (-not $godotExecutable) { $godotExecutable = Get-Command 'godot' -ErrorAction Stop }
& $godotExecutable.Source --headless --path $repoDirectory --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot-Import fehlgeschlagen.' }
$playtestData = Join-Path $repoDirectory '.godot\boss_stage_playtest\userdata'
New-Item -ItemType Directory -Path $playtestData -Force | Out-Null
$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $godotExecutable.Source
$startInfo.WorkingDirectory = $repoDirectory
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
$startInfo.Environment['APPDATA'] = $playtestData
foreach ($argument in @('--path', $repoDirectory, '--script', 'res://tools/play_boss_stage.gd', '--', "--boss=$Boss", "--build=$Build", "--difficulty=$Difficulty", '--start-paused')) {
    $startInfo.ArgumentList.Add($argument)
}
if ($Full) { $startInfo.ArgumentList.Add('--full') }
if ($Trial) { $startInfo.ArgumentList.Add('--trial') }
$playtestProcess = [System.Diagnostics.Process]::Start($startInfo)
Write-Output "Boss-Test gestartet (PID $($playtestProcess.Id)). F4: Build/Wellen. Eigene Test-Spielstaende."

