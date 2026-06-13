---
name: worktree-management
description: >
  Standardized git worktree workflow for feature, fix, and hotfix branches. Use this
  skill whenever creating a feature branch (feat/*, feature/*), a fix branch (fix/*,
  hotfix/*, bugfix/*), or any branch work that is NOT a direct commit to main.
  Activate when the user says "work on", "implement", "build", "fix", or "start a
  branch for" something that requires isolation, or when the global CLAUDE.md
  Git Worktrees section references this procedure. Covers .worktrees/ gitignore
  verification, project-local worktree creation, dependency install (pip / npm /
  dotnet auto-detect), clean-baseline test run, and post-merge cleanup. Do NOT
  use this skill for single-file doc or config changes committed directly to main,
  or for read-only operations such as audits and reports.
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

# Worktree Management

## When to Use

**ALWAYS use this skill when:**
- Creating a feature branch (`feature/*`, `feat/*`)
- Creating a fix/hotfix branch (`fix/*`, `hotfix/*`, `bugfix/*`)
- Any branch work that is NOT a direct commit to `main`
- The user says "work on", "implement", "build", or "fix" something that requires a new branch

**Do NOT use when:**
- Making single-file doc/config changes committed directly to `main`
- Running read-only operations (audits, reports, analysis)
- The user explicitly says to work in the current directory

## Convention

All projects use **project-local `.worktrees/`** directories:

```
<projects-root>\<ProjectName>\
├── .worktrees\
│   ├── feature-new-dashboard\    ← isolated workspace
│   └── fix-login-bug\            ← isolated workspace
├── src\
├── CLAUDE.md
└── .gitignore                    ← MUST contain .worktrees/
```

## Procedure

### 1. Verify `.worktrees/` Is Gitignored

Before creating any worktree, verify the directory won't be tracked:

```powershell
# Check if .worktrees is ignored (global or local gitignore)
git check-ignore -q .worktrees 2>$null
if ($LASTEXITCODE -ne 0) {
    # NOT ignored — fix immediately
    Add-Content -Path .gitignore -Value "`n# Git worktrees`n.worktrees/"
    git add .gitignore
    git commit -m "chore: add .worktrees/ to .gitignore"
}
```

**This is non-negotiable.** Never create a worktree without confirming it's ignored.

### 2. Create the Worktree

```powershell
# Sanitize branch name for directory (replace / with -)
$dirName = $branchName -replace '/', '-'

# Create worktree with new branch
git worktree add ".worktrees/$dirName" -b $branchName

# Or for an existing remote branch
git worktree add ".worktrees/$dirName" $branchName
```

### 3. Change to Worktree Directory

```powershell
Set-Location ".worktrees/$dirName"
```

### 4. Install Dependencies (Auto-Detect)

```powershell
# Python
if (Test-Path "requirements.txt") { pip install -r requirements.txt }
if (Test-Path "pyproject.toml") { pip install -e ".[dev]" }

# Node.js
if (Test-Path "package.json") { npm install }

# .NET
if (Get-ChildItem "*.csproj" -ErrorAction SilentlyContinue) { dotnet restore }
```

### 5. Verify Clean Baseline

Run the project's test suite to confirm the worktree starts clean:

```powershell
# Use project-appropriate test command
pytest          # Python
npm test        # Node.js
dotnet test     # .NET
```

If tests fail: **Report failures and ask whether to proceed.** Do not silently continue.

### 6. Report Ready

```
Worktree ready at <projects-root>\<Project>\.worktrees\<branch-dir>
Branch: <branch-name>
Tests: <N> passing, 0 failures
Ready to implement <feature-description>
```

## Cleanup (After Merge)

When work is complete and the branch has been merged:

```powershell
# Return to main working directory
Set-Location (git rev-parse --show-toplevel)

# Remove the worktree
git worktree remove ".worktrees/$dirName"

# Prune stale worktree references
git worktree prune

# Delete the branch if merged
git branch -d $branchName
```

If `git worktree remove` fails due to Windows file locks, use:
```powershell
git worktree remove --force ".worktrees/$dirName"
```

## Listing Active Worktrees

```powershell
git worktree list
```

## Rules

1. **Never skip gitignore verification** — worktree contents in git history is a serious problem
2. **Never have two worktrees on the same branch** — git enforces this, don't try to work around it
3. **Always run tests before starting work** — establishes a clean baseline
4. **Always clean up after merge** — orphaned worktrees waste disk and can lock files on Windows
5. **Use the PowerShell scripts when available** — `New-Worktree.ps1` and `Remove-Worktree.ps1` handle all safety checks automatically

## Integration

This skill is invoked automatically by the `## Git Worktrees` section in `~/.claude/CLAUDE.md`. Claude Code sessions should use worktrees for all branch-based work without being asked.

## Eval Cases

Prompts that should trigger this skill:

- "Implement the new dashboard filter feature" — new feature work requires a branch
- "Work on fix for the login timeout bug" — fix branch required
- "Start a hotfix for the broken CSV export" — hotfix/* branch pattern
- "Build the email notification module" — "build" keyword + new branch needed
- "[PROJ-99] Add YAML frontmatter to the regression-check skill" — multi-file ticket work in a repo

Prompts that should NOT trigger this skill:

- "Update the README to fix the typo in the setup section" — single-file doc change to main
- "Can you show me the git log for the last week?" — read-only operation
- "Run the regression check audit" — audit/report, no branch needed
- "What does the worktree-management skill do?" — informational query, no code changes
