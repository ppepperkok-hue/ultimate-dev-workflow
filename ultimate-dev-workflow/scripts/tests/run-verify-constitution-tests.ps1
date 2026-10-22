<#
.SYNOPSIS
    Dependency-free regression tests for scripts/verify-constitution.ps1 and the
    CLI dispatch safety defaults in references/09a-cli-dispatch.md.

.DESCRIPTION
    Creates throwaway fixtures under the system temp directory, runs the
    verifier in a child PowerShell process, and asserts exit codes plus
    stable ASCII fragments of the output. No Pester, no modules, no network.

    Works with Windows PowerShell 5.1 and PowerShell 7+.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/run-verify-constitution-tests.ps1

.EXAMPLE
    pwsh -File scripts/tests/run-verify-constitution-tests.ps1
#>
$ErrorActionPreference = "Stop"

$testDir = $PSScriptRoot
$scriptsDir = Split-Path -Parent $testDir
$skillRoot = Split-Path -Parent $scriptsDir

$verifier = Join-Path (Join-Path $skillRoot "scripts") "verify-constitution.ps1"
$template = Join-Path (Join-Path $skillRoot "templates") "AGENTS.md.template"
$dispatchDoc = Join-Path (Join-Path $skillRoot "references") "09a-cli-dispatch.md"

foreach ($requiredPath in @($verifier, $template, $dispatchDoc)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        [Console]::Error.WriteLine("FAIL: required file not found: $requiredPath")
        exit 1
    }
}

$hostExe = (Get-Process -Id $PID).Path
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("vc-tests-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempRoot | Out-Null

$script:passed = 0
$script:failed = 0

function Check {
    param(
        [string]$Name,
        [bool]$Condition,
        [string]$Detail = ""
    )
    if ($Condition) {
        Write-Host "PASS: $Name"
        $script:passed++
    }
    else {
        $script:failed++
        Write-Host "FAIL: $Name"
        if ($Detail.Trim().Length -gt 0) {
            Write-Host "      output: $($Detail.Trim())"
        }
    }
}

function New-CaseDir {
    param([string]$Name)
    $dir = Join-Path $tempRoot $Name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    return $dir
}

function New-TemplateCase {
    param([string]$Name)
    $dir = New-CaseDir $Name
    Copy-Item -LiteralPath $template -Destination (Join-Path $dir "AGENTS.md")
    return $dir
}

function New-ReferenceFreeCase {
    # Template content with its inline-code spans replaced, so the fixture keeps
    # the mandatory sections but starts with zero references. Cases that assert
    # the resolved-reference count need that clean baseline.
    param([string]$Name)
    $dir = New-CaseDir $Name
    $raw = Get-Content -LiteralPath $template -Raw -Encoding UTF8
    $stripped = [regex]::Replace($raw, '`[^`]+`', 'code')
    Set-Content -LiteralPath (Join-Path $dir "AGENTS.md") -Value $stripped -Encoding UTF8
    return $dir
}

function Add-DocLine {
    param(
        [string]$AgentsPath,
        [string]$Text
    )
    Add-Content -LiteralPath $AgentsPath -Value $Text -Encoding UTF8
}

function ConvertTo-UncShare {
    # Local admin share form of a drive path: C:\x -> \\localhost\C$\x. Only
    # used by the UNC cases, which run when that share is reachable.
    param([string]$WindowsPath)
    return ("\\localhost\" + (($WindowsPath -replace '^([A-Za-z]):', '$1$') -replace '/', '\'))
}

function Invoke-Verifier {
    param([string]$CasePath)
    # Windows PowerShell 5.1 turns redirected native stderr into a terminating
    # error while ErrorActionPreference is Stop; relax it only for the call.
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $hostExe -NoProfile -ExecutionPolicy Bypass -File $verifier -Path $CasePath 2>&1 | Out-String
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

try {
    # 1. Legitimate constitution template must pass.
    $case = New-TemplateCase "valid-template"
    $result = Invoke-Verifier $case
    Check "legitimate template passes (exit 0)" ($result.ExitCode -eq 0) $result.Output

    # 2. The confirmed 402-byte junk file must fail on content, not size.
    $case = New-CaseDir "junk-402-bytes"
    $junkPath = Join-Path $case "AGENTS.md"
    Set-Content -LiteralPath $junkPath -Value (("x" * 401) + "`n") -Encoding ASCII -NoNewline
    Check "junk fixture is exactly 402 bytes" ((Get-Item -LiteralPath $junkPath).Length -eq 402)
    $result = Invoke-Verifier $case
    Check "402-byte junk fails (exit 1)" ($result.ExitCode -eq 1) $result.Output
    Check "junk failure names validation-discipline" ($result.Output -match "validation-discipline") $result.Output

    # 3. Missing AGENTS.md must fail fast.
    $case = New-CaseDir "missing-agents"
    $result = Invoke-Verifier $case
    Check "missing AGENTS.md fails (exit 1)" ($result.ExitCode -eq 1) $result.Output
    Check "missing AGENTS.md message is explicit" ($result.Output -match "AGENTS.md not found") $result.Output

    # 4. Existing markdown link passes; missing one fails.
    $case = New-TemplateCase "link-exists"
    $docsDir = Join-Path $case "docs"
    New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $docsDir "rules.md") -Value "# Rules" -Encoding UTF8
    Add-DocLine (Join-Path $case "AGENTS.md") "See [rules](docs/rules.md)."
    $result = Invoke-Verifier $case
    Check "existing markdown link passes (exit 0)" ($result.ExitCode -eq 0) $result.Output

    $case = New-TemplateCase "link-missing"
    Add-DocLine (Join-Path $case "AGENTS.md") "See [rules](docs/rules.md)."
    $result = Invoke-Verifier $case
    Check "missing markdown link fails (exit 1)" ($result.ExitCode -eq 1) $result.Output
    Check "missing link names the path" ($result.Output -match "docs/rules.md") $result.Output
    Check "missing link reports markdown-link kind" ($result.Output -match "markdown-link") $result.Output

    # 5. Inline-code paths are checked too.
    $case = New-TemplateCase "inline-code-missing"
    Add-DocLine (Join-Path $case "AGENTS.md") 'Rule: `scripts/check.ps1`.'
    $result = Invoke-Verifier $case
    Check "missing inline-code path fails (exit 1)" ($result.ExitCode -eq 1) $result.Output
    Check "missing inline-code path reports kind" ($result.Output -match "inline-code") $result.Output

    # 6. Fenced code samples and external references are not promises.
    $case = New-TemplateCase "ignored-examples"
    $fence = @(
        '```text',
        'See [rules](docs/missing.md) and `scripts/missing.ps1`.',
        '```',
        'See [Codex](https://github.com/openai/codex) and [section](#validation).',
        'See [placeholder](<docs/missing rules.md>).',
        'Dynamic route `src/[id].tsx` is a pattern, not a path.'
    )
    Add-Content -LiteralPath (Join-Path $case "AGENTS.md") -Value $fence -Encoding UTF8
    $result = Invoke-Verifier $case
    Check "fenced examples, URLs, anchors, placeholders ignored (exit 0)" ($result.ExitCode -eq 0) $result.Output

    # 7. Fragments resolve against the file path.
    $case = New-TemplateCase "fragment-link"
    $docsDir = Join-Path $case "docs"
    New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $docsDir "rules.md") -Value "# Rules" -Encoding UTF8
    Add-DocLine (Join-Path $case "AGENTS.md") "See [rules](docs/rules.md#top)."
    $result = Invoke-Verifier $case
    Check "markdown fragment link resolves (exit 0)" ($result.ExitCode -eq 0) $result.Output

    # 8. Dot-prefixed relative paths are still validated.
    $case = New-TemplateCase "dot-relative-missing"
    Add-DocLine (Join-Path $case "AGENTS.md") 'See `./scripts/missing.ps1`.'
    $result = Invoke-Verifier $case
    Check "dot-relative missing path fails (exit 1)" ($result.ExitCode -eq 1) $result.Output

    # 9. Dropping a mandatory section must fail.
    $case = New-TemplateCase "missing-required-section"
    $agentsPath = Join-Path $case "AGENTS.md"
    $lines = @(Get-Content -LiteralPath $agentsPath -Encoding UTF8)
    $headingIndexes = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^## ") { $headingIndexes += $i }
    }
    $lastHeading = $headingIndexes[$headingIndexes.Count - 1]
    Set-Content -LiteralPath $agentsPath -Value $lines[0..($lastHeading - 1)] -Encoding UTF8
    $result = Invoke-Verifier $case
    Check "missing mandatory section fails (exit 1)" ($result.ExitCode -eq 1) $result.Output
    Check "missing section names conflict-rules" ($result.Output -match "conflict-rules") $result.Output

    # 10. Absolute Windows paths are checked, existing and missing.
    $case = New-ReferenceFreeCase "absolute-path-exists"
    $absoluteFile = Join-Path $case "abs-ok.md"
    Set-Content -LiteralPath $absoluteFile -Value "# abs" -Encoding UTF8
    Add-DocLine (Join-Path $case "AGENTS.md") ("See [abs]({0})." -f $absoluteFile)
    $result = Invoke-Verifier $case
    Check "absolute windows path passes (exit 0)" ($result.ExitCode -eq 0) $result.Output
    Check "absolute windows path is checked, not skipped" ($result.Output -match "1 local reference") $result.Output

    $case = New-ReferenceFreeCase "absolute-path-missing"
    $absentFile = Join-Path $case "abs-gone.md"
    Add-DocLine (Join-Path $case "AGENTS.md") ("See [abs]({0})." -f $absentFile)
    $result = Invoke-Verifier $case
    Check "missing absolute windows path fails (exit 1)" ($result.ExitCode -eq 1) $result.Output
    Check "missing absolute windows path is named" ($result.Output -match "abs-gone\.md") $result.Output

    # 11. ``../`` references that leave the project root are checked too.
    $outsideDir = Join-Path $tempRoot "outside-root"
    New-Item -ItemType Directory -Path $outsideDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $outsideDir "ok.md") -Value "# out" -Encoding UTF8

    $case = New-ReferenceFreeCase "outside-root-exists"
    Add-DocLine (Join-Path $case "AGENTS.md") 'See [out](../outside-root/ok.md).'
    $result = Invoke-Verifier $case
    Check "dotdot outside root passes (exit 0)" ($result.ExitCode -eq 0) $result.Output
    Check "dotdot outside root is checked, not skipped" ($result.Output -match "1 local reference") $result.Output

    $case = New-ReferenceFreeCase "outside-root-missing"
    Add-DocLine (Join-Path $case "AGENTS.md") 'See [out](../outside-root/gone.md).'
    $result = Invoke-Verifier $case
    Check "missing dotdot outside root fails (exit 1)" ($result.ExitCode -eq 1) $result.Output
    Check "missing dotdot outside root reports resolved path" ($result.Output -match "outside-root") $result.Output

    # 12. UNC admin shares end a segment with a literal ``$``; that is a path,
    # not a variable. Skipped when the local admin share is not reachable.
    $adminShare = "\\localhost\C$"
    if (Test-Path -LiteralPath $adminShare) {
        $case = New-ReferenceFreeCase "unc-path-exists"
        $uncFile = Join-Path $case "unc-ok.md"
        Set-Content -LiteralPath $uncFile -Value "# unc" -Encoding UTF8
        Add-DocLine (Join-Path $case "AGENTS.md") ("See [unc]({0})." -f (ConvertTo-UncShare $uncFile))
        $result = Invoke-Verifier $case
        Check "absolute UNC path passes (exit 0)" ($result.ExitCode -eq 0) $result.Output
        Check "absolute UNC path is checked, not skipped" ($result.Output -match "1 local reference") $result.Output

        $case = New-ReferenceFreeCase "unc-path-missing"
        Add-DocLine (Join-Path $case "AGENTS.md") ("See [unc]({0})." -f (ConvertTo-UncShare (Join-Path $case "unc-gone.md")))
        $result = Invoke-Verifier $case
        Check "missing UNC path fails (exit 1)" ($result.ExitCode -eq 1) $result.Output
        Check "missing UNC path is named" ($result.Output -match "unc-gone\.md") $result.Output
    }
    else {
        Write-Host "SKIP: UNC cases (\\localhost\C`$ not reachable on this host)"
    }

    # 13. Variable-style paths stay unchecked.
    $case = New-ReferenceFreeCase "variables-ignored"
    Add-Content -LiteralPath (Join-Path $case "AGENTS.md") -Value @(
        'Run `$env:TEMP\missing.md` now.',
        'Build `%TEMP%\missing.md` now.'
    ) -Encoding UTF8
    $result = Invoke-Verifier $case
    Check "variable-style paths are ignored (exit 0)" ($result.ExitCode -eq 0) $result.Output
    Check "variable-style paths are not counted" ($result.Output -match "0 local reference") $result.Output

    # 14. Dispatch guide must not ship copyable sandbox bypass defaults.
    $dispatch = Get-Content -LiteralPath $dispatchDoc -Raw -Encoding UTF8
    $forbiddenFlag = "dangerously" + "-bypass"
    Check "dispatch guide ships no sandbox bypass flag" (-not ($dispatch -match $forbiddenFlag)) "bypass flag still present"
    Check "implementation default uses workspace-write" ($dispatch -match "codex exec -s workspace-write") "workspace-write default missing"
    Check "review default stays read-only" ($dispatch -match "codex exec review --commit <sha> -o") "review command changed"
    Check "cross-platform bash commands preserved" (($dispatch -match '(?m)^```bash') -and ($dispatch -match "/tmp/report.md")) "bash block missing"
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host ("Result: {0} passed, {1} failed." -f $script:passed, $script:failed)
if ($script:failed -gt 0) { exit 1 }
exit 0
