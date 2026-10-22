<#
.SYNOPSIS
    Verify a project constitution (AGENTS.md) before Phase 1 starts.

.DESCRIPTION
    Checks, in order:
      1. AGENTS.md exists at the project root (or the -Path leaf itself).
      2. The file is non-empty and above a small byte floor (default 200).
      3. The mandatory section keywords named in references/04d-enforce-read.md
         are present: 验证纪律, 权限边界, 冲突规则.
      4. Every local path referenced from prose resolves to an existing file or
         directory. Markdown links and inline-code paths are checked. External
         URLs, anchors, placeholder paths, and examples inside fenced code
         blocks are ignored.

    Exit code 0 means all checks passed; 1 means at least one issue was found
    and printed as a FAIL line on stderr.

    This is a structural smoke check, not a semantic review. It cannot prove
    that the rules are good, only that the mandatory entries exist and that the
    paths the constitution points at are real.

.PARAMETER Path
    Project root that contains AGENTS.md. Defaults to the current directory.

.PARAMETER MinimumBytes
    Byte floor for AGENTS.md. Defaults to 200. The keyword checks are the real
    content gate; this floor only rejects near-empty stubs early.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/verify-constitution.ps1 -Path .

.EXAMPLE
    pwsh -File scripts/verify-constitution.ps1 -Path C:\work\my-project
#>
[CmdletBinding()]
param(
    [string]$Path = ".",
    [int]$MinimumBytes = 200
)

$ErrorActionPreference = "Stop"

function Write-Failure {
    param([string]$Message)
    [Console]::Error.WriteLine("FAIL: $Message")
}

function Test-ExternalOrPlaceholder {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
    $v = $Value.Trim()
    if ($v.StartsWith("#")) { return $true }
    if ($v.StartsWith("//")) { return $true }
    if ($v -match '[<>{}*%|=\[\]]') { return $true }        # placeholder or glob
    # A "$" only starts a variable when something variable-ish follows it
    # ($env:TEMP, ${root}/x, $(...)). UNC admin shares end a segment with a
    # literal "$" (\\host\C$\project\x.md); treating that as a placeholder
    # skipped every UNC reference, so a broken one still reported success.
    if ($v -match '\$[A-Za-z0-9_{(]') { return $true }
    if ($v -match '^[A-Za-z]:[\\/]') { return $false }       # Windows absolute path
    if ($v -match '^\\\\') { return $false }                 # Windows UNC path
    if ($v -match '^[A-Za-z][A-Za-z0-9+.-]*:') { return $true } # URL or other scheme
    if ($v -match '^[/~]') { return $true }                   # POSIX absolute / home
    return $false
}

# Resolve the project root. Accept either a directory or the AGENTS.md file.
$root = $Path
if (Test-Path -LiteralPath $root -PathType Leaf) {
    $leafItem = Get-Item -LiteralPath $root
    if ($leafItem.Name -ne "AGENTS.md") {
        Write-Failure "expected a directory or an AGENTS.md file, got: $Path"
        exit 1
    }
    $root = $leafItem.DirectoryName
}
elseif (-not (Test-Path -LiteralPath $root -PathType Container)) {
    Write-Failure "project root not found: $Path"
    exit 1
}
$root = (Resolve-Path -LiteralPath $root).ProviderPath

$agents = Join-Path $root "AGENTS.md"
if (-not (Test-Path -LiteralPath $agents -PathType Leaf)) {
    Write-Failure "AGENTS.md not found: $agents"
    exit 1
}

$bytes = (Get-Item -LiteralPath $agents).Length
try {
    $content = [string](Get-Content -LiteralPath $agents -Raw -Encoding UTF8)
}
catch {
    Write-Failure "cannot read AGENTS.md: $($_.Exception.Message)"
    exit 1
}

$failures = New-Object System.Collections.Generic.List[string]

if ($content.Trim().Length -eq 0) {
    $failures.Add("AGENTS.md is empty.") | Out-Null
}
if ($bytes -lt $MinimumBytes) {
    $failures.Add("AGENTS.md too small ($bytes bytes; minimum $MinimumBytes); constitution likely incomplete.") | Out-Null
}

# Mandatory entries from 04d-enforce-read.md. Keyword matching is deliberate:
# projects may trim optional sections or change heading levels, but these three
# entries must survive.
$requiredSections = @(
    @{ Keyword = "验证纪律"; Id = "validation-discipline" },
    @{ Keyword = "权限边界"; Id = "permissions-boundary" },
    @{ Keyword = "冲突规则"; Id = "conflict-rules" }
)
foreach ($section in $requiredSections) {
    if ($content.IndexOf($section.Keyword, [System.StringComparison]::Ordinal) -lt 0) {
        $failures.Add("missing required section keyword '$($section.Keyword)' ($($section.Id)).") | Out-Null
    }
}

# Collect prose references. Fenced code blocks are examples, not promises.
$script:references = New-Object System.Collections.Generic.List[object]
$script:seenReferences = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)

function Add-Reference {
    param(
        [string]$Raw,
        [int]$Line,
        [string]$Kind
    )
    if (Test-ExternalOrPlaceholder $Raw) { return }

    $clean = ($Raw -replace '[#?].*$', '').Trim()
    if ($clean.Length -eq 0) { return }

    # Inline-code spans must look like paths; this filters commands and flags.
    if ($Kind -eq "inline-code") {
        if ($clean -match '\s') { return }
        if ($clean -eq "." -or $clean -eq "..") { return }
        if ($clean -match '^-{1,2}[A-Za-z]') { return }
        if ($clean -notmatch '[\\/]' -and $clean -notmatch '\.md$') { return }
    }

    if ($clean -match '^[A-Za-z]:[\\/]' -or $clean -match '^\\\\') {
        $full = $clean
    }
    else {
        $full = Join-Path $root $clean
        try { $full = [System.IO.Path]::GetFullPath($full) } catch { }
    }

    if (-not $script:seenReferences.Add($full)) { return }
    $script:references.Add([pscustomobject]@{
        Reference = $clean
        FullPath  = $full
        Line      = $Line
        Kind      = $Kind
    }) | Out-Null
}

$lineNumber = 0
$inFence = $false
foreach ($line in ($content -split "`r?`n")) {
    $lineNumber++
    if ($line -match '^\s{0,3}(```|~~~)') {
        $inFence = -not $inFence
        continue
    }
    if ($inFence) { continue }

    foreach ($linkMatch in [regex]::Matches($line, '\[[^\]]*\]\(([^)]+)\)')) {
        $destination = $linkMatch.Groups[1].Value.Trim()
        if ($destination -notmatch '^[<]' -and $destination -match '^(\S+)\s+') {
            $destination = $Matches[1]   # markdown title after the destination
        }
        Add-Reference -Raw $destination -Line $lineNumber -Kind "markdown-link"
    }

    foreach ($codeMatch in [regex]::Matches($line, '`([^`]+)`')) {
        Add-Reference -Raw $codeMatch.Groups[1].Value -Line $lineNumber -Kind "inline-code"
    }
}

foreach ($reference in $script:references) {
    $exists = $false
    try { $exists = Test-Path -LiteralPath $reference.FullPath } catch { $exists = $false }
    if (-not $exists) {
        $failures.Add("missing referenced path '$($reference.Reference)' (line $($reference.Line), $($reference.Kind)): resolved to '$($reference.FullPath)'.") | Out-Null
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { Write-Failure $failure }
    Write-Failure "constitution verification failed with $($failures.Count) issue(s)."
    exit 1
}

Write-Host ("OK: AGENTS.md present, {0} bytes; required sections present; {1} local reference(s) resolved." -f $bytes, $script:references.Count)
exit 0
