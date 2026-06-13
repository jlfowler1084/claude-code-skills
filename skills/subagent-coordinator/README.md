# Subagent Coordinator Skill

A Claude Code protocol for safely delegating multi-file work to specialized subagents. The coordinator plans, delegates implementation, verifies, optionally reviews — and **always owns the commit itself**, never delegating it.

## What This Skill Does

A five-phase protocol:

1. **PLAN** — analyze the change, decide whether it needs a branch, capture a pre-change snapshot (line counts + test baseline).
2. **EXECUTE** — delegate to an implementer with a structured contract (task, scope, acceptance criteria, constraints).
3. **VERIFY** — a read-only qa-agent confirms tests pass and file integrity holds, with an optional clean-checkout smoke gate for risky diffs.
4. **REVIEW** *(optional)* — a code-reviewer pass for core-logic or security-sensitive changes.
5. **COMMIT** — coordinator-owned, following the safe-commit protocol.

Reference docs cover cost awareness (token multipliers, tier selection), error recovery (per-phase), and rules for parallel multi-agent delegation.

## Installation

```bash
# Global (all projects)
cp -r skills/subagent-coordinator ~/.claude/skills/subagent-coordinator

# Per-project
cp -r skills/subagent-coordinator .claude/skills/subagent-coordinator
```

Pairs with [`git-branching`](../git-branching/), [`safe-commit`](../safe-commit/), and [`hunt`](../hunt/).
