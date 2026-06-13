# API Cost Governance Skill

A Claude Code skill that enforces cost discipline before any outbound AI/API call and standardizes model-tier selection — so sessions don't reach for an expensive model (or an AI call at all) when something cheaper would do.

## What This Skill Does

- **Pre-call cascade:** before spending on an AI call, check whether a direct MCP/REST call, rules-based logic, or a cached result would do the job.
- **Tier selection:** a Haiku / Sonnet / Opus table keyed to a "does this need Claude to THINK, or just DO?" heuristic — with guidance that the same mapping extends to other providers or local models.
- **Declared intent:** prompt and task files carry an explicit model-tier declaration with a one-line justification, flagged if missing.

## Installation

```bash
# Global (all projects)
cp -r skills/api-governance ~/.claude/skills/api-governance

# Per-project
cp -r skills/api-governance .claude/skills/api-governance
```
