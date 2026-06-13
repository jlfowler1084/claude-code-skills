# Prompt Engineering Skill

A Claude Code skill for writing session-handoff prompt files and choosing the right model tier when handing work between planning and execution sessions.

## What This Skill Does

- **Invocation syntax:** the `@prompts/file.md` prompt-loading form (and the `--prompt-file` flag that does *not* exist).
- **Model tier selection:** a Haiku / Sonnet / Opus table mapping task profiles ("just DO" / "THINK + DO" / "THINK DEEPLY") to tiers, with the typical plan-in-Opus → execute-in-Sonnet flow.
- **Prompt-file contents:** what's required (ticket line, model declaration, justification) versus optional, and what belongs inline versus in a handoff file.

## Installation

```bash
# Global (all projects)
cp -r skills/prompt-engineering ~/.claude/skills/prompt-engineering

# Per-project
cp -r skills/prompt-engineering .claude/skills/prompt-engineering
```
