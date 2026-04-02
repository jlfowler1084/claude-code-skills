# PowerShell Windows Skill

A Claude Code skill that enforces production PowerShell patterns across all AI-assisted script generation. When installed, Claude Code produces scripts with proper advanced functions, structured logging, error handling, and Windows integration — patterns that experienced PowerShell developers expect but AI tools typically omit.

## What This Skill Does

Without this skill, Claude Code generates PowerShell that works but isn't production-ready: bare `param()` blocks without `CmdletBinding`, `Write-Host` instead of proper streams, no `OutputType`, string concatenation for paths, and scheduled tasks that pop up visible console windows.

With this skill installed, every PowerShell script Claude Code generates follows the patterns in the 13 sections below.

## The 13 Sections

| # | Section | What It Enforces |
|---|---------|-----------------|
| 1 | **Advanced Functions** | `[CmdletBinding()]`, typed parameters, `[OutputType()]`, parameter sets, `begin/process/end/cleanup` blocks, `ShouldProcess` for state changes |
| 2 | **Splatting** | Hashtable-based parameter passing for readability, conditional parameter addition, multi-splat patterns |
| 3 | **Tab Completion** | `Register-ArgumentCompleter` for paths, dynamic values, `IValidateSetValuesGenerator` classes, module registration patterns |
| 4 | **Error Handling** | `ErrorActionPreference` strategy by context, typed catch blocks, `$PSCmdlet.ThrowTerminatingError()` for guaranteed termination |
| 5 | **Structured Logging** | JSON log files with `ConvertTo-Json -Depth 10`, Windows Event Log integration, event ID conventions (1000/2000/3000 ranges) |
| 6 | **Task Scheduler** | `LogonType S4U` to prevent visible windows, `pwsh.exe` arguments, task folder conventions, health verification |
| 7 | **Operator Syntax** | Parentheses for logical operators, null checks before property access, string interpolation patterns |
| 8 | **Encoding** | ASCII-only status indicators, UTF-8 file encoding, no emoji/unicode in scripts |
| 9 | **Common Pitfalls** | Quick-reference table mapping error messages to causes and fixes |
| 10 | **File Paths** | `Join-Path` over concatenation, `$PSScriptRoot` for relative paths, existence checks |
| 11 | **PSScriptAnalyzer** | Pre-commit analysis, key rules to never suppress, integration guidance |
| 12 | **Production Template** | Complete script template with `#Requires`, comment-based help, structured logging, try/catch with exit codes |
| 13 | **Module Template** | Function template for `.psm1` modules with tab completion registration |

## Sources

This skill was built from a combination of authoritative PowerShell references and real-world operations experience:

- **Chris Dent**, *Mastering PowerShell Scripting*, 4th Ed (Packt, 2021) — Chapters 17, 18, 21, 22
- **Michael Kofler**, *Scripting: Automation with Bash, PowerShell, and Python* (Rheinwerk, 2024) — Chapters 4, 10, 11
- **Lee Holmes**, *PowerShell Cookbook*, 4th Ed (O'Reilly, 2021)
- **20 years** of enterprise IT operations experience

## Validation Results

This skill has been validated through two real-world production deployments:

### Task Scheduler Audit Script (first script built under the skill)

- Full `CmdletBinding` with `SupportsShouldProcess`
- `[OutputType()]` on all functions
- Splatting for all multi-parameter cmdlet calls
- Structured JSON + Windows Event Log logging
- Tab completion for parameters
- PSScriptAnalyzer clean (zero warnings, zero errors)

### Module Retrofit (84-function PowerShell module)

| Metric | Before | After |
|--------|--------|-------|
| PSScriptAnalyzer findings | 529 | 17 |
| OutputType coverage | 0% | 100% |
| Write-Host calls | 442 | 0 |
| Functions with CmdletBinding | partial | 84/84 |

The remaining 17 findings are intentional suppressions (e.g., `PSAvoidUsingWriteHost` in a logging function that wraps `Write-Host` for console-only output).

## Before / After

### Without the skill

```powershell
param($Path, $Days)

$cutoff = (Get-Date).AddDays(-$Days)
$files = Get-ChildItem $Path -Recurse | Where-Object { $_.LastWriteTime -lt $cutoff }

Write-Host "Found $($files.Count) old files"

foreach ($f in $files) {
    Write-Host "Removing $($f.FullName)"
    Remove-Item $f.FullName -Force
}

Write-Host "Done!"
```

### With the skill installed

```powershell
#Requires -Version 7.0

<#
.SYNOPSIS
    Removes files older than a specified number of days.
.DESCRIPTION
    Scans the target directory recursively and removes files that have not
    been modified within the specified retention period. Supports -WhatIf
    for dry-run verification.
.PARAMETER Path
    Directory to scan for old files.
.PARAMETER Days
    Retention period in days. Files older than this are removed.
.EXAMPLE
    .\Remove-OldFiles.ps1 -Path C:\Logs -Days 30
    Removes log files older than 30 days.
.EXAMPLE
    .\Remove-OldFiles.ps1 -Path C:\Logs -Days 30 -WhatIf
    Shows which files would be removed without deleting anything.
#>

[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path,

    [Parameter(Mandatory)]
    [ValidateRange(1, 3650)]
    [int]$Days
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$cutoff = (Get-Date).AddDays(-$Days)
$removed = 0

$params = @{
    Path        = $Path
    Recurse     = $true
    File        = $true
    ErrorAction = 'SilentlyContinue'
}
$oldFiles = Get-ChildItem @params | Where-Object { $_.LastWriteTime -lt $cutoff }

Write-Verbose "Found $($oldFiles.Count) files older than $Days days in $Path"

foreach ($file in $oldFiles) {
    if ($PSCmdlet.ShouldProcess($file.FullName, "Remove file")) {
        Remove-Item -LiteralPath $file.FullName -Force
        $removed++
        Write-Verbose "Removed: $($file.FullName)"
    }
}

[PSCustomObject]@{
    Path         = $Path
    DaysRetained = $Days
    FilesFound   = $oldFiles.Count
    FilesRemoved = $removed
}
```

## Installation

### Global (all projects)

```bash
mkdir -p ~/.claude/skills/powershell-windows
cp SKILL.md ~/.claude/skills/powershell-windows/SKILL.md
```

### Per-Project

```bash
mkdir -p .claude/skills/powershell-windows
cp SKILL.md .claude/skills/powershell-windows/SKILL.md
```
