---
name: prompt-engineering
description: >
  Use when creating a session-handoff prompt file, switching model tiers between
  planning and execution sessions, or invoking Claude Code with a prompt file.
  Trigger phrases: "write a prompt file", "create a session handoff", "hand off to
  Sonnet", "hand off to Haiku", "create a handoff prompt", "which model should I
  use", "how do I invoke this", "save this as a prompt". Do NOT trigger for general
  questions about the current session that require no handoff artifact.
---

# Prompt Engineering Skill

## Purpose

Encode the conventions for Claude Code session-handoff prompt files. Covers filename
convention, model selection, invocation syntax, and what belongs in a prompt file
versus handled inline.

## Invocation Syntax

CORRECT:
```
claude --model sonnet "@prompts/PROJ-235-rewire-audit.md"
```

WRONG (no such flag exists):
```
claude --model sonnet --prompt-file prompts/PROJ-235-rewire-audit.md
```

The `@` prefix loads the file as the initial prompt. There is no `--prompt-file` flag.

## Model Tier Selection

| Tier   | When to use                                              | Task profile      |
|--------|----------------------------------------------------------|-------------------|
| Haiku  | File ops, find-replace, boilerplate, docs, git ops       | just DO           |
| Sonnet | New features, refactoring, debugging, tests              | THINK + DO        |
| Opus   | Architecture, multi-step planning, codebase audits       | THINK DEEPLY      |

Typical flow: plan in Opus, execute in Sonnet, minor cleanup in Haiku.

## Filename Convention

```
prompts/TICKET-summary-slug.md
```

Examples:
- `prompts/PROJ-235-rewire-audit.md`
- `prompts/PROJ-228-docs-manifest.md`
- `prompts/APP-115-dashboard-filter-fix.md`

## What Goes in a Prompt File

Required:
1. **Ticket reference line** at the top: `[TICKET-ID] One-sentence summary`
2. **Model tier declaration**: `Model: SONNET` (or HAIKU / OPUS)
3. **Justification**: one sentence explaining why that tier

Optional but common:
- Reference to the plan file: `Read docs/plans/your-plan.md`
- Phase 0 branch setup steps
- Specific work to execute (not the full plan — the handoff context only)
- Critical gotchas and anti-patterns surfaced during planning
- Stop-gate checkpoints for multi-phase work

Keep it execution-focused. Planning prose and background belong in your planning docs.

## When to Create a Prompt File

Create one when:
- Handing off from a planning session to an execution session
- The model tier needs to change (planned in Opus, executing in Sonnet)
- The work spans multiple sessions and needs a stable re-entry point
- Delegating to a subagent via `claude --model X "@prompts/FILE.md"`

Work inline (no prompt file needed) when:
- The session is self-contained with no planned handoff
- The task is small enough that context fits in the current session
- You are running a quick fix or config change directly

## Artifact Locations

- `prompts/` -- session-handoff prompts (lightweight, execution-focused)
- `docs/plans/` -- full planning docs with metadata (archive, not invoked directly)
- `docs/solutions/` -- knowledge compounding (post-completion writeups)
