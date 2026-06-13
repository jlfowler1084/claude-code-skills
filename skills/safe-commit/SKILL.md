---
name: safe-commit
description: >
  Pre-commit verification workflow that prevents branch contamination, file truncation,
  and premature done declarations. Use when committing code, finishing a task, before
  pushing changes, or before switching branches. Trigger when the user says "commit",
  "push", "done with this task", "ready to merge", or any variation of completing work
  and saving to git. Use for every commit workflow to catch common friction patterns.
---

# Safe Commit

A pre-commit verification workflow that prevents the most common friction patterns:
branch contamination, file truncation, and premature "done" declarations.

## Steps

1. **Verify branch**: Run `git branch` and confirm we're on the expected branch. If the branch name doesn't match the current task, STOP and alert the user. In any repo with a branch-and-PR policy file (`.claude/worktree-policy.json`), verify you are on a worktree branch (not `main`) per the Policy Enforcement section in the `git-branching` skill.

2. **Check for stray commits**: Run `git log --oneline -5` and verify no commits from other feature branches have leaked in. Look for commit messages that reference different tickets/issues than the current task.

3. **Verify file integrity**: Run `git diff --stat` and check that:
   - No files have been truncated (large deletions without corresponding additions)
   - No unexpected files were modified
   - If any file shows a net loss of more than 50 lines, flag it for user review

4. **Scan staged files for secrets**: Run `git diff --cached -U0` and check the output for common secret patterns:
   - API key assignments: `grep -iE "(api_key|api_secret|client_secret|access_token|auth_token)\s*[=:]\s*['\"][^'\"]{8,}"`
   - Password assignments: `grep -iE "password\s*[=:]\s*['\"][^'\"]{6,}"`
   - Known key prefixes: `grep -E "(sk-[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{36})"` (OpenAI, AWS, GitHub PAT)
   - Connection strings with inline credentials: `grep -iE "(postgres|mysql|mongodb|redis)://[^@]+:[^@]+@"`
   If any match is found, STOP and ask the user to review before proceeding. Template/example values in test fixtures are acceptable; real credentials in production code are not.

4.5. **Optional local-model pre-commit review** (when available): If your project provides a pre-commit review script — for example, one that routes the staged diff through a local model for fast semantic triage — run it from the repo root.
   - **CRITICAL** findings: block the commit; override only deliberately.
   - **WARNING** findings: prompt the user to confirm before continuing.
   - **INFO** findings: log only, no interruption.
   - If no such script is present, the diff exceeds the script's size limit, or the local model is offline, this step skips silently — the commit is never blocked by an LLM outage.

5. **Run tests**: Execute the project's test suite:
   - Python projects: `python -m pytest tests/ -x -q`
   - PowerShell projects: run the project-specific test command
   - Report pass/fail counts explicitly

6. **Commit**: If all checks pass, create a commit with a conventional commit message (`feat:`, `fix:`, `refactor:`, etc.). Reference the relevant ticket/issue if your project uses one.

7. **Verify commit**: Run `git log --oneline -3` to confirm the commit landed on the correct branch.

8. **Push**: Push to the remote and confirm success.

## When to Use
- After completing any feature, bug fix, or refactor
- Before switching branches or starting a new task
- After subagent tasks complete (verify integrity first)

## Failure Modes This Prevents
- Branch contamination (commits from feature-A leaking into feature-B)
- File truncation (subagents overwriting 700-line files with 8-line stubs)
- Premature "done" (declaring success without running tests)
- Wrong-branch commits (committing to master instead of feature branch)
