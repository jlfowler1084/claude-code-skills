# Safe Commit Skill

A Claude Code pre-commit verification workflow that catches the friction patterns most likely to bite AI-assisted commits: branch contamination, file truncation, leaked secrets, and premature "done" declarations.

## What This Skill Does

An 8-step gate run before every commit:

1. Verify you're on the expected branch (and a worktree branch, if a branch-and-PR policy is in force).
2. Check for stray commits leaked from other branches.
3. File-integrity check — flag large net deletions that suggest truncation.
4. Secret scan with concrete grep patterns (API keys, passwords, known key prefixes, connection strings).
5. Optional local-model pre-commit review, if your project provides one (skips silently otherwise).
6. Run the test suite and report pass/fail explicitly.
7. Commit with a conventional message.
8. Verify the commit landed on the right branch, then push.

## Installation

```bash
# Global (all projects)
cp -r skills/safe-commit ~/.claude/skills/safe-commit

# Per-project
cp -r skills/safe-commit .claude/skills/safe-commit
```

Pairs with [`git-branching`](../git-branching/).
