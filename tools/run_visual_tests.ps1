param(
    [ValidateSet('4.7.2', '4.8-dev4')][string]$Motor = '4.7.2',
    [switch]$Import,
    [switch]$Baseline,
    [string]$Script = 'res://tools/verify_visual.gd',
    [string]$Project = (Split-Path $PSScriptRoot -Parent)
)
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath $Project).Path
$engine = if ($Motor -eq '4.8-dev4') {
    'C:\Users\bruni\OneDrive\Desktop\Apps\Godot_v4.8-dev4_win64.exe'
} else {
    'C:\Users\bruni\OneDrive\Desktop\Apps\Godot 4.7.2\godot.cmd'
}
$logs = Join-Path $project 'tmp'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$tag = if ($Import) { 'import' } elseif ($Baseline) { 'antes' } else { [IO.Path]::GetFileNameWithoutExtension($Script) }
$stdout = Join-Path $logs "$Motor-$tag-stdout.log"
$stderr = Join-Path $logs "$Motor-$tag-stderr.log"
$arguments = @('--path', '.', '--windowed', '--audio-driver', 'Dummy')
if ($Import) {
    $arguments += @('--headless', '--editor', '--import', '--quit')
} else {
    $arguments += @('--resolution', '1280x640', '--script', $Script)
    $arguments += @('--', "test_session=$([guid]::NewGuid().ToString('N'))")
    if ($Baseline) { $arguments += 'baseline=1' }
}
$process = $null
try {
    $process = Start-Process -FilePath $engine -ArgumentList $arguments -WorkingDirectory $project `
        -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    if (-not $process.WaitForExit(120000)) {
        throw 'La prueba excedio 120 segundos.'
    }
    Get-Content -LiteralPath $stdout
    Get-Content -LiteralPath $stderr
    $bad = Select-String -LiteralPath $stdout,$stderr -Pattern 'SCRIPT ERROR|^ERROR:'
    if ($process.ExitCode -ne 0 -or $bad) { exit 1 }
} finally {
    if ($process -and -not $process.HasExited) {
        & taskkill.exe /PID $process.Id /T /F | Out-Null
    }
}
