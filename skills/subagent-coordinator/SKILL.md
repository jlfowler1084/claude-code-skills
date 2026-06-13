---
name: subagent-coordinator
description: >
  Use when a task touches 3 or more files, spans both implementation and test changes,
  or modifies shared modules where corruption risk is high. Trigger when the user says
  "use subagents", "delegate this", "run this in parallel", "coordinate the agents",
  or when a plan assigns work across multiple streams. Also trigger when the task is
  complex enough that a single long session risks context loss. Do NOT use for
  single-file changes, docs-only updates, or tasks completable in under 5 minutes —
  those should run inline without delegation overhead.
---

# Subagent Coordinator Protocol

You are the coordinator. You manage the workflow by delegating to specialized subagents and validating their outputs before committing. You NEVER delegate the commit step — that's always your responsibility.

## When to Use This Protocol

**USE subagents when:**
- Task modifies 3+ files
- Task involves both implementation AND testing
- Task touches core logic or shared modules
- You need context isolation (long session, complex codebase)

**SKIP subagents when:**
- Single-file change under 50 lines
- Documentation or config-only updates
- Quick bug fix with obvious solution
- Task is completable in under 5 minutes

## Phase 1: PLAN

Before delegating anything:

1. **Analyze the task** — What needs to change? Which files? What are the risks?

2. **Decide on branching** — branch for risk, not process:
   - 3+ files or core logic? Create a feature branch:
     ```bash
     git checkout -b feature/PROJ-XXX-short-description
     ```
   - Simple change? Stay on current branch.

3. **Capture pre-change snapshot**:
   ```bash
   echo "=== Pre-Change Snapshot ===" > /tmp/pre-change-snapshot.txt
   echo "Branch: $(git branch --show-current)" >> /tmp/pre-change-snapshot.txt
   echo "=== File Line Counts ===" >> /tmp/pre-change-snapshot.txt
   wc -l <file1> <file2> <file3> >> /tmp/pre-change-snapshot.txt
   echo "=== Test Baseline ===" >> /tmp/pre-change-snapshot.txt
   <test-command> >> /tmp/pre-change-snapshot.txt 2>&1
   echo "Exit code: $?" >> /tmp/pre-change-snapshot.txt
   ```

4. **Write the delegation contract** for the implementer (see format below).

## Phase 2: EXECUTE

Delegate to the **implementer** agent with a structured handoff:

```
TASK: [one-line description]
SCOPE: [specific files/directories — be explicit]
ACCEPTANCE CRITERIA:
  1. [what must be true when done]
  2. [what must be true when done]
CONSTRAINTS:
  - Use Edit (not Write) for all existing files
  - Only modify files listed in SCOPE
  - Run tests before reporting done
PRE-CHANGE SNAPSHOT:
  [paste relevant line counts from snapshot]
BRANCH: [current branch name]
```

When the implementer returns:
- Check that STATUS is DONE (not FAILED or BLOCKED)
- Verify the diff looks reasonable
- If FAILED or BLOCKED, address the issue and re-delegate

## Phase 3: VERIFY

Delegate verification to the **qa-agent** (read-only): confirm tests pass, check file integrity, and run a regression check if the project has one. See `references/error-recovery.md` for how to route QA outcomes (pass / fix-and-retry / escalate to the user).

**Clean-checkout smoke gate (recommended for risky diffs).** When a change touches tests, fixtures, generators, or build tooling, run the affected tests from a *fresh checkout* of the candidate commit (a temporary detached worktree), not from inside the authoring worktree. This catches artifacts that only exist locally — untracked fixtures, generated files that were never committed — and regressions that only surface against the committed tree. Do not merge if the clean-checkout run fails.

## Phase 4: REVIEW (Optional)

For risky changes (core logic, shared modules, security-sensitive code), delegate to the **code-reviewer**:

```
REVIEW: [brief description]
DIFF: [paste git diff or list changed files]
FOCUS: [security | performance | conventions | all]
```

**Review outcomes:**
- No CRITICAL findings → Proceed to Phase 5
- CRITICAL findings → Back to Phase 2 to address them
- WARNINGS only → Your judgment — fix now or note for later

## Phase 5: COMMIT

**YOU (the coordinator) own all commits to `main` and all PR merges — never delegated. Worktree-isolated subagents MAY commit within their own worktree branch; the coordinator merges those branches in dependency order.**

Follow the safe-commit skill protocol:
1. Verify correct branch: `git branch --show-current`
2. Check for stray changes: `git status`
3. Stage changes: `git add <specific-files>` (never `git add .` blindly)
4. Final integrity check: `git diff --cached --stat`
5. Commit with a conventional message: `git commit -m "feat(scope): description"`
6. Verify: `git log --oneline -1`
7. Push if appropriate

## Parallel Execution

See `references/parallel-execution.md` for rules on multi-instance parallel delegation.

## Error Recovery

See `references/error-recovery.md` for per-phase recovery procedures.

## Cost Awareness

See `references/cost-awareness.md` for token multiplier guidance and model tier selection.
