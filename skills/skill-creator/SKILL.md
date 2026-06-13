---
name: skill-creator
description: >
  Use when authoring a new SKILL.md from scratch, refactoring an existing skill that
  is too long or triggers poorly, writing eval cases for a skill, or deciding whether
  a workflow belongs as a global vs project-scoped skill. Trigger when the user says
  "create a skill", "add a skill", "turn this into a skill", "the skill isn't
  triggering", "write evals for this skill", "this skill is too long", or asks how to
  structure a SKILL.md. Does not cover CLAUDE.md authoring, agent persona files, or
  prose-quality review of existing skills — use technical-writing for those.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
---

# Skill Creator

Guide the creation of new skills and improvement of existing ones, following the
Agent Skills spec and a modular, thin-trigger shape.
Skills authored through this skill default to thin (60–150 line) trigger documents
with detailed content extracted to `references/` and runnable code in `scripts/`.

## When to Use

- Authoring a new skill from scratch (greenfield)
- Refactoring a heavy or monolithic SKILL.md (>200 lines) into the modular shape
- Improving an existing skill's triggering or compliance posture
- Writing eval cases for a skill with objectively verifiable outputs
- Reviewing a draft SKILL.md against the convention before merge
- Deciding whether a workflow pattern belongs as a global or project-scoped skill

## When Not to Use

- Reading or analyzing existing skill code without making changes
- Reviewing prose quality of an existing SKILL.md — delegate to `technical-writing`
- Authoring CLAUDE.md, agent definitions, or commands — those have separate conventions

---

## Reference Docs

| # | File | Read when… |
|---|------|-----------|
| 1 | [thin-skill-template.md](references/thin-skill-template.md) | Authoring a new SKILL.md or refactoring an existing one — copyable skeleton with section-by-section guidance |
| 2 | [modular-decomposition.md](references/modular-decomposition.md) | Deciding what stays inline in SKILL.md vs extracts to `references/` |
| 3 | [token-cost-model.md](references/token-cost-model.md) | Understanding why progressive disclosure matters; cost framing for authoring decisions |
| 4 | [eval-cases.md](references/eval-cases.md) | Authoring, running, or recording eval cases for a skill |

---

## Capture Intent (Diagnostic Checklist)

Before writing the SKILL.md, answer these. Each answer drives a specific
authoring decision:

1. **What should this skill enable Claude to do?** Core workflow or capability in
   one sentence.
2. **When should this skill trigger?** Concrete phrases, contexts, file shapes.
   Skills under-trigger by default; descriptions must be "pushy" — explicit
   "Use when…" phrases listing specific conditions, not abstract category names.
3. **What's the expected output?** Files created, console output, code changes,
   or reports.
4. **Global or project-scoped?** Global if the pattern is reusable across repos;
   project-scoped if it references project-specific paths, APIs, or domain
   terminology. Global skills live in `~/.claude/skills/<name>/`;
   project-scoped in `<project>/.claude/skills/<name>/`.
5. **Should we author eval cases?** Yes for objectively verifiable outputs; skip
   for subjective outputs (style, design, editorial judgment). See
   [eval-cases.md](references/eval-cases.md).
6. **Are there existing scripts or tools to wrap?** Check for PowerShell scripts,
   Python tools, or reference docs that belong in `scripts/` or `references/`.

---

## Directory Structure

```
skill-name/
+-- SKILL.md          # Required — thin trigger doc, target 60-150 lines
+-- references/       # Detailed content loaded on demand (the bulk of detail lives here)
+-- scripts/          # Runnable code invoked by the skill (validators, wrappers)
+-- assets/           # Optional — templates, resources
+-- evals/
    +-- evals.json    # Eval definitions
    +-- fixtures/     # Test input files
    +-- results/      # One JSON per eval run
```

Defaults: every new skill should have `SKILL.md` and `references/`. Add `scripts/`
only if the skill ships runnable code (not just illustrative snippets). Add
`evals/` only if outputs are objectively verifiable.

---

## Frontmatter Rules

- **`name`** must match the directory name; lowercase letters, numbers, hyphens.
  No leading, trailing, or consecutive hyphens.
- **`description`** is the only triggering surface. 50–300 characters. Lead with
  what the skill does (one sentence). Follow with explicit "Use when…" or
  "Trigger when…" phrases. Include concrete keywords users would actually type.
  See [token-cost-model.md](references/token-cost-model.md) for why description
  length is a real per-session cost paid in every Claude Code session.
- **`allowed-tools`** lists what the skill body actually requires. Author the
  smallest list the skill genuinely needs — not every tool the author had open.

---

## Quick Reference

| Step | Command |
|------|---------|
| Validate compliance | Run your skill linter, if you have one (checks frontmatter, name/dir match, line-count thresholds) |
| Install a skill | Copy the skill dir to `~/.claude/skills/<name>/` (global) or `<project>/.claude/skills/<name>/` (per-project) |
| Commit format | `feat(skills): add <skill-name> skill` (or `optimize`, `refactor`) |

All ERRORs from compliance must be resolved before merge. WARNINGs should be
addressed unless the PR explains why an exception is acceptable.

---

## Iteration After Shipping

If the skill under-triggers or produces poor results:

1. Review eval results (if any) and any user feedback or failed sessions.
2. Decide whether the description (Tier 1), body (Tier 2), or a reference (Tier 3)
   needs to change. The [token-cost-model.md](references/token-cost-model.md)
   doc explains the tier distinction.
3. Re-run evals if they exist; commit only if pass rate improves over the
   previous commit. The eval-result `skill_commit` field correlates quality back
   to specific source states.

---

## Related Skills

- `technical-writing` — prose quality and structural Markdown validation
- `claude-md-management:claude-md-improver` — CLAUDE.md authoring (different convention)
