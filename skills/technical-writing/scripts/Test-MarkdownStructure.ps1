<#
.SYNOPSIS
    Validates Markdown files for structural issues.
.DESCRIPTION
    Checks three structural properties of Markdown files:

      1. Heading hierarchy -- heading levels must not skip. h1 directly to h3
         (with no h2 in between) is flagged as a gap.
      2. Local link targets -- relative [text](path) references must resolve to
         an existing file. External URLs and pure fragment links (#anchor) are skipped.
      3. Code-fence balance -- the count of triple-backtick fence markers must be
         even. An odd count indicates an unclosed fence block.

    Exit codes:
      0  No structural issues found in any checked file
      1  One or more structural issues found
      2  Invocation error (file not found, invalid path)

    Standalone: this script has no repository-specific dependencies. The exit-code
    and JSON-report shape are stable; if you wire a downstream audit to them, treat
    the contract as frozen.
.PARAMETER Path
    Path to a Markdown file to check. Accepts pipeline input via FullName property
    (compatible with Get-ChildItem output).
.PARAMETER ReportPath
    Optional path to write a JSON findings report. The report is an array of
    objects, one per checked file, each with: File (string), Pass (bool),
    Findings (array of {Line, Check, Message}).
.EXAMPLE
    .\Test-MarkdownStructure.ps1 -Path README.md

    Checks README.md and prints a terse PASS/FAIL summary line.
.EXAMPLE
    Get-ChildItem docs/ -Filter '*.md' -Recurse | .\Test-MarkdownStructure.ps1

    Checks all docs Markdown files. Exits 1 if any file has structural issues.
.EXAMPLE
    .\Test-MarkdownStructure.ps1 -Path README.md -Verbose

    Checks README.md with a per-finding breakdown in the verbose stream.
.EXAMPLE
    .\Test-MarkdownStructure.ps1 -Path README.md -ReportPath "$env:TEMP\report.json"

    Checks README.md and writes a JSON findings report to the specified path.
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string]$Path,

    [Parameter()]
    [string]$ReportPath
)

begin {
    $ErrorActionPreference = 'Stop'
    $allResults = [System.Collections.Generic.List[PSCustomObject]]::new()
    $anyFailure = $false

    function Get-MarkdownFindings {
        [CmdletBinding()]
        [OutputType([PSCustomObject[]])]
        param(
            [Parameter(Mandatory)]
            [string]$FilePath
        )

        $resolvedPath = (Resolve-Path $FilePath).Path
        $fileDir      = Split-Path $resolvedPath -Parent
        $rawContent   = Get-Content -Path $resolvedPath -Raw -Encoding UTF8
        $content      = if ($rawContent) { $rawContent } else { '' }
        $lines        = $content -split '\n'
        $findings     = [System.Collections.Generic.List[PSCustomObject]]::new()

        # --- Check 1: Heading hierarchy ---
        # Flags any transition where heading level jumps by more than 1 when going deeper.
        # Going back up (h3 -> h1) is always allowed.
        $prevLevel = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^(#{1,6})\s') {
                $level = $matches[1].Length
                if ($prevLevel -ne -1 -and $level -gt ($prevLevel + 1)) {
                    $findings.Add([PSCustomObject]@{
                        Line    = $i + 1
                        Check   = 'heading-gap'
                        Message = "Heading jumped from h$prevLevel to h$level (expected h$($prevLevel + 1))"
                    })
                }
                $prevLevel = $level
            }
        }

        # --- Check 2: Code-fence balance ---
        # Counts lines that start with ``` (with optional leading whitespace).
        # An odd count means at least one fence block was never closed.
        $fenceCount = @($lines | Where-Object { $_ -match '^\s*```' }).Count
        if ($fenceCount % 2 -ne 0) {
            $findings.Add([PSCustomObject]@{
                Line    = 0
                Check   = 'fence-balance'
                Message = "Unbalanced code fences: $fenceCount triple-backtick marker(s) (expected an even number)"
            })
        }

        # --- Check 3: Local link targets ---
        # Resolves relative [text](path) links against the file's directory.
        # Skips external URLs, mailto: links, and pure fragment (#anchor) links.
        foreach ($match in [regex]::Matches($content, '\[([^\]]*)\]\(([^)]+)\)')) {
            $target = $match.Groups[2].Value.Trim()
            if ($target -match '^https?://' -or $target -match '^mailto:' -or $target -match '^#') { continue }
            $pathPart = ($target -split '#')[0]
            if (-not $pathPart) { continue }
            $absTarget = Join-Path $fileDir $pathPart
            if (-not (Test-Path $absTarget)) {
                $lineNum = ($content.Substring(0, $match.Index) -split '\n').Count
                $findings.Add([PSCustomObject]@{
                    Line    = $lineNum
                    Check   = 'broken-link'
                    Message = "Broken local link: '$pathPart' not found"
                })
            }
        }

        return $findings.ToArray()
    }
}

process {
    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path" -ErrorAction Continue
        exit 2
    }

    $findings = Get-MarkdownFindings -FilePath $Path
    $pass     = ($findings.Count -eq 0)
    $resolved = (Resolve-Path $Path).Path
    $allResults.Add([PSCustomObject]@{
        File     = $resolved
        Pass     = $pass
        Findings = $findings
    })

    if (-not $pass) { $anyFailure = $true }

    $issueWord = if ($findings.Count -eq 1) { 'issue' } else { 'issues' }
    if ($pass) {
        Write-Output "PASS  $resolved -- no structural issues"
    } else {
        Write-Output "FAIL  $resolved -- $($findings.Count) structural $issueWord found"
    }

    foreach ($f in $findings) {
        $lineRef = if ($f.Line -gt 0) { "line $($f.Line)" } else { 'file-level' }
        Write-Verbose "  [$($f.Check)] ${lineRef}: $($f.Message)"
    }
}

end {
    if ($ReportPath) {
        $allResults | ConvertTo-Json -Depth 5 |
            Set-Content -Path $ReportPath -Encoding UTF8 -NoNewline
        Write-Verbose "Report written to: $ReportPath"
    }

    if ($anyFailure) { exit 1 }
    exit 0
}
