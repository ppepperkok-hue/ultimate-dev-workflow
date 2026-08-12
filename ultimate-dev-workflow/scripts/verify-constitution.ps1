# Usage: powershell -ExecutionPolicy Bypass -File verify-constitution.ps1 -Path <project-root>
param([string]$Path = ".")
$ErrorActionPreference = "Stop"

$agents = Join-Path $Path "AGENTS.md"
if (-not (Test-Path -LiteralPath $agents)) {
    Write-Error "AGENTS.md not found: $agents"
    exit 1
}

$len = (Get-Item -LiteralPath $agents).Length
if ($len -lt 200) {
    Write-Error "AGENTS.md too small ($len bytes); constitution likely incomplete."
    exit 1
}

Write-Host "OK: AGENTS.md present, $len bytes."
exit 0
