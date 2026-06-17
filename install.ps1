<#
.SYNOPSIS
    Mirrors the canonical packet-capture skill into one or more AI agent skill directories.

.DESCRIPTION
    Copies (or optionally symlinks) the `skills/packet-capture` directory tree into the
    target agent's skill discovery path under a configurable root.

    Supported agents and their target paths:
        Claude  ->  <Root>/.claude/skills/packet-capture/
        Codex   ->  <Root>/.agents/skills/packet-capture/
        Gemini  ->  <Root>/.gemini/skills/packet-capture/
        Qwen    ->  <Root>/.qwen/skills/packet-capture/

    The operation is idempotent: re-running removes any previously installed copy and
    replaces it cleanly, preventing nested directories from accumulating.
    The canonical source is always `<script dir>/skills/packet-capture`.

.PARAMETER Targets
    One or more agents to install into. Accepts any combination of Claude, Codex, Gemini,
    and Qwen. Defaults to all four.

.PARAMETER Root
    Base directory under which each agent's skill path is created. Defaults to $HOME.
    Set to a temp path during testing.

.PARAMETER Symlink
    When specified, creates a directory junction (Windows) instead of copying files.
    Falls back to a full copy with a warning if the symlink cannot be created
    (e.g. missing privilege or unsupported file system).

.EXAMPLE
    pwsh ./install.ps1
    # Installs into all four agent directories under $HOME.

.EXAMPLE
    pwsh ./install.ps1 -Targets Claude, Codex
    # Installs only into the Claude and Codex skill directories under $HOME.

.EXAMPLE
    pwsh ./install.ps1 -Targets Claude -Root C:\Temp\test-root -Symlink
    # Creates a directory junction for Claude under C:\Temp\test-root (elevated required).
#>
[CmdletBinding()]
param (
    [ValidateSet('Claude', 'Codex', 'Gemini', 'Qwen')]
    [string[]] $Targets = @('Claude', 'Codex', 'Gemini', 'Qwen'),

    [string] $Root = $HOME,

    [switch] $Symlink
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---- Resolve canonical source -----------------------------------------------
$sourcePath = Join-Path $PSScriptRoot 'skills' 'packet-capture'

if (-not (Test-Path $sourcePath)) {
    Write-Error "[ERROR] Source skill directory not found: $sourcePath"
    exit 1
}

# ---- Agent -> relative path map ---------------------------------------------
$agentMap = [ordered]@{
    'Claude' = '.claude/skills'
    'Codex'  = '.agents/skills'
    'Gemini' = '.gemini/skills'
    'Qwen'   = '.qwen/skills'
}

# ---- Install per target ------------------------------------------------------
foreach ($target in $Targets) {
    $relPath     = $agentMap[$target]
    $skillsDir   = Join-Path $Root $relPath
    $destPath    = Join-Path $skillsDir 'packet-capture'

    Write-Host "[INFO] $target -> $destPath"

    # Ensure the parent skills directory exists
    if (-not (Test-Path $skillsDir)) {
        New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    }

    if ($Symlink) {
        # Try to create a directory junction; fall back to copy on failure
        try {
            # Remove existing destination if present (required before New-Item junction)
            if (Test-Path $destPath) {
                Remove-Item $destPath -Recurse -Force
            }
            New-Item -ItemType Junction -Path $destPath -Target $sourcePath -Force | Out-Null
            Write-Host "[OK]   $target symlink created: $destPath -> $sourcePath"
        }
        catch {
            Write-Warning "[WARN] Symlink creation failed for $target ($($_.Exception.Message)). Falling back to copy."
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
            Write-Host "[OK]   $target copied (fallback): $destPath"
        }
    }
    else {
        # Remove existing destination before copying to prevent nesting on re-run
        if (Test-Path $destPath) {
            Remove-Item $destPath -Recurse -Force
        }
        Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
        Write-Host "[OK]   $target installed: $destPath"
    }
}
