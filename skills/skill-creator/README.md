# Skill Creator Skill

A meta-skill for authoring new Claude Code skills and refactoring existing ones into a clean, modular shape — thin `SKILL.md` triggers with detail extracted to `references/`.

## What This Skill Does

Guides skill authoring end to end:
- **Capture Intent** checklist — what the skill enables, when it should trigger, expected output, global vs. project scope, whether to write evals.
- **Directory structure** — the thin-SKILL.md + `references/` + optional `scripts/` layout.
- **Frontmatter rules** — name/dir match, the description as the only triggering surface, minimal `allowed-tools`.
- **Iteration loop** — diagnosing under-triggering and deciding which tier (description / body / reference) to change.

## What's Inside (references)

| Reference | Covers |
|-----------|--------|
| thin-skill-template.md | a copyable SKILL.md skeleton with section-by-section guidance |
| modular-decomposition.md | extract-vs-inline heuristics, grounded in real refactors |
| token-cost-model.md | why thin triggers + on-demand references keep per-session cost low |
| eval-cases.md | authoring, running, and recording eval cases |

## Installation

```bash
# Global (all projects)
cp -r skills/skill-creator ~/.claude/skills/skill-creator

# Per-project
cp -r skills/skill-creator .claude/skills/skill-creator
```
