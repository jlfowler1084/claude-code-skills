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

    The operation is idempotent: re-running replaces the canonical skill files cleanly
    (no nested packet-capture/packet-capture directories accumulate) while PRESERVING a
    user-created local-context.md in the installed directory across reinstalls/updates.
    That protects the per-machine customization the skill instructs users to create next
    to local-context.template.md. The canonical source is always
    `<script dir>/skills/packet-capture`.

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

# ---- Helpers ----------------------------------------------------------------

# Remove an installed path safely. If it is a reparse point (junction/symlink), delete
# ONLY the link so we never recurse into and destroy the target's contents (which could
# be the source repository clone).
function Remove-InstalledPath {
    param([Parameter(Mandatory)][string] $Path)
    if (-not (Test-Path $Path)) { return }
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        [System.IO.Directory]::Delete($Path, $false)
    }
    else {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}

# Copy the skill into $Dest, preserving a user-created local-context.md across reinstall.
# The destination is replaced cleanly to avoid nested directories, but the user's
# per-machine customization file is stashed and restored.
function Copy-SkillPreservingContext {
    param(
        [Parameter(Mandatory)][string] $Source,
        [Parameter(Mandatory)][string] $Dest
    )
    $preserved = $null
    $existingContext = Join-Path $Dest 'local-context.md'
    if (Test-Path $existingContext) {
        $preserved = Join-Path ([System.IO.Path]::GetTempPath()) ("pc-localctx-" + [guid]::NewGuid().ToString() + ".md")
        Copy-Item -LiteralPath $existingContext -Destination $preserved -Force
    }

    Remove-InstalledPath -Path $Dest
    Copy-Item -Path $Source -Destination $Dest -Recurse -Force

    if ($preserved) {
        Copy-Item -LiteralPath $preserved -Destination (Join-Path $Dest 'local-context.md') -Force
        Remove-Item -LiteralPath $preserved -Force
        Write-Host "[KEEP] $Dest local-context.md preserved across reinstall"
    }
}

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
    $relPath   = $agentMap[$target]
    $skillsDir = Join-Path $Root $relPath
    $destPath  = Join-Path $skillsDir 'packet-capture'

    Write-Host "[INFO] $target -> $destPath"

    if (-not (Test-Path $skillsDir)) {
        New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    }

    if ($Symlink) {
        try {
            Remove-InstalledPath -Path $destPath
            New-Item -ItemType Junction -Path $destPath -Target $sourcePath -Force | Out-Null
            Write-Host "[OK]   $target symlink created: $destPath -> $sourcePath"
        }
        catch {
            Write-Warning "[WARN] Symlink creation failed for $target ($($_.Exception.Message)). Falling back to copy."
            Copy-SkillPreservingContext -Source $sourcePath -Dest $destPath
            Write-Host "[OK]   $target copied (fallback): $destPath"
        }
    }
    else {
        Copy-SkillPreservingContext -Source $sourcePath -Dest $destPath
        Write-Host "[OK]   $target installed: $destPath"
    }
}
