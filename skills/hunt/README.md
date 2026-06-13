# Hunt — Parallel Bug Investigation Skill

A Claude Code skill that debugs by fan-out: decompose a bug into independent hypotheses, investigate each one with a parallel **read-only** agent, then synthesize a ranked root-cause assessment with a falsification test *before* any fix is applied.

## What This Skill Does

- **Phase 1 — Decompose:** turn the bug into 3–8 independent hypotheses (regression, code-pattern, fixture, dependency, environment, logs, …), scaled to the bug's scope.
- **Phase 2 — Dispatch:** one read-only investigation agent per hypothesis, all running in parallel.
- **Phase 3 — Synthesize:** rank findings by confidence and convergence, pick the most likely root cause, and generate a falsification test.
- **Phase 4 — Implement (opt-in):** only after you confirm, dispatch an implementer to apply the fix in a worktree and run the full suite.

The discipline that makes it work: investigation agents are always read-only (no working-tree contamination before the cause is confirmed), one hypothesis per agent, and a mandatory falsification test.

## Installation

```bash
# Global (all projects)
cp -r skills/hunt ~/.claude/skills/hunt

# Per-project
cp -r skills/hunt .claude/skills/hunt
```

Pairs with [`subagent-coordinator`](../subagent-coordinator/) for the agent-management patterns.
