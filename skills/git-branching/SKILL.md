---
name: git-branching
description: >
  Use when starting any code change in a repo that enforces a branch-and-PR policy
  (e.g. one with a `.claude/worktree-policy.json` file), when the user asks "do I
  need a branch for this?", "can I commit directly to main?", or "how should I
  structure this branch?", or when preparing to merge or clean up a feature branch.
  Also trigger before the first commit of any session to confirm the correct branch
  is active. Does NOT govern commit message format or push authorization — see
  safe-commit for that. Does NOT apply to bare doc/config edits in non-enforced
  repos where direct-to-main is explicitly permitted.
---

# Git Branching Strategy

## When to Create a Feature Branch

Create a feature branch for work that carries meaningful risk of breaking existing functionality:
- New features spanning multiple files or modules
- Refactors that change core logic or data structures
- Any change touching 5+ files
- Experimental or exploratory work where rollback is likely
- Subagent-driven multi-task implementations
- Changes to pipeline architecture, database schema, or API contracts

## When to Commit Directly to Main

> **Note:** This section applies only in repos *without* a branch-and-PR policy file (`.claude/worktree-policy.json`). In policy-enforced repos, all of the following is superseded by the Policy Enforcement section below — every change requires a branch and PR regardless of size or risk.

These are safe to commit directly without a feature branch:
- Documentation updates (README, CLAUDE.md, comments)
- Configuration changes (.gitignore, .mcp.json, settings)
- Single-file bug fixes with clear, isolated scope
- Dependency updates (requirements.txt, package.json)
- Formatting or linting fixes

## Branch Naming

> **Note:** This convention applies only in repos without a policy file. In policy-enforced repos, branches must follow the `worktree_pattern` defined in the policy file (e.g. `worktree/<TICKET>-<slug>`). See the Policy Enforcement section below.

Convention: `feature/TICKET-short-description`

Examples:
- `feature/PROJ-123-user-auth`
- `feature/PROJ-456-add-search`

## Creating a Feature Branch

```bash
git checkout main        # or master -- use the project's default branch
git pull origin main
git checkout -b feature/TICKET-short-description
```

**Prefer worktrees over checkout.** Instead of switching branches in the main working directory, use git worktrees for isolation. See the `worktree-management` skill for the full procedure.

## Merge Strategy

Choose based on commit count:

- **1-3 commits (squash merge):** Produces one clean commit on main.
  ```bash
  git checkout main
  git merge --squash feature/TICKET-short-description
  git commit -m "feat: short description (TICKET)"
  ```

- **4+ commits (regular merge):** Preserves the full history.
  ```bash
  git checkout main
  git merge feature/TICKET-short-description
  ```

## Post-Merge Cleanup

Do all of these immediately after merging -- never leave stale branches:

1. Push main: `git push origin main`
2. Delete local branch: `git branch -d feature/TICKET-short-description`
3. Delete remote branch: `git push origin --delete feature/TICKET-short-description`

## Branch Hygiene

- Before starting any work, check for stale branches: `git branch`
  - If old feature branches exist, ask the user before cleaning up
- Never force-push to main/master without explicit user approval
- If a feature branch falls behind main, rebase before merging: `git rebase main`
- Run `git log --oneline -5` before starting work on any branch to check for stray commits
- If commits from another feature branch are present, stop and alert the user

## Optional: Branch-and-PR Policy Enforcement

Some repos opt into a strict "every change goes through a branch and PR" policy. This is valuable for shared or automation-heavy repos, where a bad direct-to-main commit would affect every future session.

### When This Section Applies

A repo enforces this policy if and only if the file `.claude/worktree-policy.json` exists in the repo root. Check for it before making any modification, including the first commit of any session. If it exists, every rule in this section applies for the whole session. If it does not exist, skip this section entirely — normal git workflows apply, and direct commits to main are acceptable when appropriate (docs-only changes, single-file fixes, initial commits, personal or scratch repos).

### Required Workflow

Before making any commits in a policy-enforced repo:

1. Create a worktree branch matching the `worktree_pattern` from the policy file (e.g. `worktree/<TICKET>-<slug>`). Use `git worktree add` to work in an isolated directory.
2. Make all commits on that branch — never on `main`.
3. Push the branch to origin.
4. Open a pull request to merge the branch into `main`.

This is the only path to `main` in an enforced repo. There are no exceptions based on change size, risk level, or file type.

### Explicit Prohibitions

- Never commit directly to `main` in a policy-enforced repo.
- Never push directly to `main` in a policy-enforced repo.
- If the policy defines a human-only override (e.g. an `ALLOW_MAIN_COMMIT` environment variable), treat it as out of scope for an automated session — it exists for human emergency use, not for the model to invoke.

### Refusal Protocol for Ambiguous Authorization

If a user instruction appears to request a direct commit or push to `main` — phrasing like "just commit it", "ship it directly", "no need for a PR", "push to main", or "skip the workflow" — do NOT proceed. The default action is always the branch-and-PR workflow.

Stop and respond with something like:

> "This repo enforces a branch-and-PR policy, so all changes go through a worktree branch and PR. I'm going to proceed with that workflow unless you tell me otherwise. If you actually need to commit directly to main for an emergency, that's a manual operation you'll need to perform yourself at your terminal."

The exact wording can vary, but the response must convey three things:

1. **The default is the workflow.** Proceed with branch-and-PR unless explicitly told not to. Never assume the user wants a bypass.
2. **A policy bypass is a human-only operation.** The model does not invoke override mechanisms or pretend to perform them on the user's behalf. If a bypass is genuinely needed, the human performs it manually at their terminal.
3. **No magic phrases.** General approval ("go ahead", "yeah fine", "do it") is not authorization to bypass. The model's only legitimate actions are: use the workflow, or stop and let the human act manually.

### Enforcement Code Is Not Exempt

Changes to the policy enforcement mechanisms themselves — git hooks, guard scripts, `.claude/worktree-policy.json`, the `git-branching` skill, the `safe-commit` skill — are especially subject to the branch-and-PR workflow, not exempt from it. A bug in enforcement affects every future session, so changes to enforcement code must be reviewable before they land on `main`.
