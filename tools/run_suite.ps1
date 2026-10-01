param([ValidateSet('4.7.2','4.8-dev4')][string]$Motor = '4.7.2')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$scripts = @(Get-ChildItem -LiteralPath (Join-Path $root 'scripts/tests') -Filter '*smoke.gd' |
    ForEach-Object { "res://scripts/tests/$($_.Name)" })
$scripts += @('res://tools/verify_visual.gd','res://tools/verify_save_isolation.gd','res://tools/verify_hub_mouse.gd','res://tools/verify_run_progression.gd','res://tools/verify_progression_ui.gd')
$failed = @()
foreach ($script in $scripts) {
    $output = @(& pwsh -NoProfile -File (Join-Path $PSScriptRoot 'run_visual_tests.ps1') -Motor $Motor -Script $script)
    $code = $LASTEXITCODE
    Write-Output "RESULT $script codigo=$code"
    if ($code -ne 0) {
        $failed += $script
        $output | Select-Object -Last 18 | Write-Output
    }
}
Write-Output "RESULT suite total=$($scripts.Count) fallos=$($failed.Count)"
if ($failed.Count) { exit 1 }
