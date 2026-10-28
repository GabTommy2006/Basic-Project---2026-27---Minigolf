param(
    [string]$GodotPath = 'C:\Program Files\Godot_v4.7.2-stable_win64.exe',
    [switch]$CheckRestart
)

$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$logRoot = Join-Path $projectPath 'tmp/test-results'
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
Set-Content -LiteralPath (Join-Path $logRoot '.gdignore') -Value ''
$suites = @(
    @('player_data_smoke', 'PLAYER_DATA_RESULT'),
    @('game_ui_smoke', 'GAME_UI_RESULT'),
    @('ui_edge_cases_smoke', 'UI_EDGE_RESULT'),
    @('gameplay_framing_smoke', 'GAMEPLAY_FRAMING_RESULT'),
    @('game_audio_smoke', 'GAME_AUDIO_RESULT'),
    @('courses_smoke', 'COURSES_RESULT'),
    @('course_camera_smoke', 'COURSE_CAMERA_RESULT'),
    @('surfaces_smoke', 'SURFACES_RESULT'),
    @('bumper_smoke', 'BUMPER_RESULT'),
    @('obstacles_smoke', 'OBSTACLES_RESULT'),
    @('portal_smoke', 'PORTAL_SMOKE_RESULT'),
    @('portal_effects_smoke', 'PORTAL_EFFECTS_RESULT'),
    @('shot_stress', 'SHOT_STRESS_RESULT')
)
$passed = 0
$failed = 0
foreach ($suite in $suites) {
    $name = $suite[0]
    $stdoutPath = Join-Path $logRoot ($name + '.out.txt')
    $stderrPath = Join-Path $logRoot ($name + '.err.txt')
    $frameLimit = if ($name -eq 'shot_stress') { '3600' } else { '1800' }
    $arguments = @(
        '--headless', '--path', ('"' + $projectPath + '"'),
        '--log-file', ('"' + (Join-Path $logRoot ($name + '.log')) + '"'),
        '--script', ('res://Tests/' + $name + '.gd'), '--quit-after', $frameLimit
    )
    # The quit limit counts rendered/process frames, not physics ticks. Cap this
    # long simulation so headless idle frames cannot exhaust its limit early.
    if ($name -eq 'shot_stress') { $arguments += @('--max-fps', '60') }
    $process = Start-Process -FilePath $GodotPath -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    $stdoutText = Get-Content -LiteralPath $stdoutPath -Raw
    $stderrText = [string](Get-Content -LiteralPath $stderrPath -Raw)
    $resultLine = ($stdoutText -split "`n" | Where-Object { $_ -match $suite[1] } | Select-Object -Last 1)
    # Assertions/parse errors can exit 0 after --quit-after, so also require the success marker and clean diagnostics.
    $ok = $process.ExitCode -eq 0 -and $resultLine -match '(failures|failed|escapes)=0\b' -and $stderrText -notmatch '(SCRIPT ERROR:|ERROR:|WARNING:)'
    if ($ok) {
        $passed++
        Write-Output ('PASS ' + $name + ': ' + $resultLine.Trim())
    } else {
        $failed++
        Write-Output ('FAIL ' + $name + ' (see ' + $stderrPath + ')')
        Write-Output $stderrText
    }
}
if ($CheckRestart) {
    $profileName = 'qa_profile_' + [guid]::NewGuid().ToString('N') + '.cfg'
    foreach ($phase in @('write', 'read', 'close', 'close-pause', 'close-result', 'read', 'reset', 'read-reset')) {
        $stdoutPath = Join-Path $logRoot ('restart-' + $phase + '.out.txt')
        $stderrPath = Join-Path $logRoot ('restart-' + $phase + '.err.txt')
        $process = Start-Process -FilePath $GodotPath -ArgumentList @(
            '--headless', '--path', ('"' + $projectPath + '"'),
            '--log-file', ('"' + (Join-Path $logRoot ('restart-' + $phase + '.log')) + '"'),
            '--script', 'res://Tests/profile_restart_worker.gd', '--quit-after', '900', '--', $phase, $profileName
        ) -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        $stdoutText = Get-Content -LiteralPath $stdoutPath -Raw
        $stderrText = [string](Get-Content -LiteralPath $stderrPath -Raw)
        if ($process.ExitCode -eq 0 -and $stdoutText.Contains('PROFILE_RESTART_OK phase=' + $phase) -and $stderrText -notmatch '(SCRIPT ERROR:|ERROR:|WARNING:)') {
            $passed++
            Write-Output ('PASS profile restart: ' + $phase)
        } else {
            $failed++
            Write-Output ('FAIL profile restart: ' + $phase)
            Write-Output $stderrText
        }
    }
}
Write-Output ('ALL_TESTS_RESULT passed=' + $passed + ' failed=' + $failed)
if ($failed -gt 0) { exit 1 }
