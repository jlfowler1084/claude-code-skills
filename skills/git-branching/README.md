# Git Branching Skill

A Claude Code skill for deciding when to branch versus commit to main, naming branches, choosing a merge strategy, and — optionally — enforcing a strict branch-and-PR policy.

## What This Skill Does

- **Risk-based branching:** clear rules for when a change needs a feature branch (multi-file work, core-logic refactors, schema/API changes) versus a safe direct-to-main commit (docs, config, single-file fixes).
- **Mechanics:** branch naming, squash-vs-regular merge selection, and disciplined post-merge cleanup.
- **Optional policy enforcement:** drop a `.claude/worktree-policy.json` into a repo and the skill enforces "every change goes through a worktree branch + PR," including a refusal protocol for ambiguous "just commit it to main" requests. Repos without that file get normal git workflows.

## Installation

```bash
# Global (all projects)
cp -r skills/git-branching ~/.claude/skills/git-branching

# Per-project
cp -r skills/git-branching .claude/skills/git-branching
```

Pairs with [`worktree-management`](../worktree-management/) (the isolated-workspace mechanics) and [`safe-commit`](../safe-commit/) (the pre-commit gate).
