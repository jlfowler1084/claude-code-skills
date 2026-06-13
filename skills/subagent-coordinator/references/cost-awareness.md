# Cost Awareness

Subagent token usage scales with complexity:
- Simple delegation (1 implementer + 1 QA): ~3-4x single session
- Full pipeline (implementer + QA + review): ~5-7x single session
- Parallel execution: multiplied by number of parallel agents

Choose wisely. Not every task needs the full pipeline. The model tiers help:
- Code Reviewer runs on **Haiku** (cheapest)
- Implementer and QA run on **Sonnet** (balanced)
- Coordinator runs on whatever the user's session model is

## When to Skip Subagents

- Single-file change under 50 lines
- Documentation or config-only updates
- Quick bug fix with obvious solution
- Task completable in under 5 minutes
