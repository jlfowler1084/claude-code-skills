# Worktree Management Skill

A Claude Code skill for an isolated git **worktree** workflow on Windows/PowerShell — so feature, fix, and hotfix branches never pollute (or get accidentally committed from) the main working directory.

## What This Skill Does

A standardized procedure for branch work:
- Verifies `.worktrees/` is gitignored *before* creating anything (worktree contents in git history is a serious problem).
- Creates a project-local worktree on a new or existing branch.
- Auto-detects and installs dependencies (pip / npm / dotnet).
- Runs the test suite to establish a clean baseline before work starts.
- Cleans up worktree and branch after merge, with a `--force` fallback for Windows file locks.

## Installation

```bash
# Global (all projects)
cp -r skills/worktree-management ~/.claude/skills/worktree-management

# Per-project
cp -r skills/worktree-management .claude/skills/worktree-management
```

Pairs with [`git-branching`](../git-branching/) for the branch-vs-main decision and naming conventions.
