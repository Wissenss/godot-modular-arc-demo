$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$documents = @('AGENTS.md', 'claude.md', 'README.md',
    'Narrativa/00_MUST_READ_PARA_IAS.md',
    'Narrativa/02_DIRECTORIO_DEL_PROYECTO.md', 'Narrativa/PLAN_ORGANIZACION.md')
$failures = [System.Collections.Generic.List[string]]::new()
$checks = 0
foreach ($document in $documents) {
    $path = Join-Path $root $document
    $content = Get-Content -LiteralPath $path -Raw
    foreach ($match in [regex]::Matches($content, '\[[^\]]+\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Split('#')[0]
        if (-not $target -or $target -match '^https?://') { continue }
        $checks++
        if (-not (Test-Path -LiteralPath (Join-Path (Split-Path $path -Parent) $target))) {
            $failures.Add("$document : $target")
        }
    }
    foreach ($match in [regex]::Matches($content, '`([^`\r\n]+/[^`\r\n]+\.(?:gd|tscn|md|ps1|res|json))`')) {
        $target = $match.Groups[1].Value
        $checks++
        if (-not (Test-Path -LiteralPath (Join-Path $root $target))) {
            $failures.Add("$document : $target")
        }
    }
}
Write-Output "RESULT enlaces=$checks fallos=$($failures.Count)"
if ($failures.Count) { $failures | Write-Output; exit 1 }
Write-Output 'PASS entrada y directorio'
