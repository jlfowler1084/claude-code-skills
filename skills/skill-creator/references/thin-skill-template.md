# Thin SKILL.md Template

Copyable skeleton for new skill authoring. Derived from the modular refactors
(`python-architecture` 500→96, `python-core` 549→97, `nextjs-supabase` 935→60,
`powershell-windows` 849→97).

Use this shape unless you have a specific reason not to. Skills that follow it stay
under the 150-line WARNING threshold and load cleanly into Claude Code's
progressive-disclosure model.

---

## When to Copy This Template

- Authoring a new skill from scratch (`skill-creator` invocation, greenfield)
- Refactoring a heavy SKILL.md (>200 lines) into the modular shape
- Reviewing an existing skill against the modular convention

If the skill is genuinely tiny (<60 lines, no `references/` needed), the full skeleton
is overkill — strip the reference table and keep just frontmatter + purpose +
when-to-use bullets.

---

## The Skeleton

Copy everything between the `BEGIN TEMPLATE` and `END TEMPLATE` markers. Replace
ALL_CAPS placeholders with skill-specific content. Do not delete sections; if a
section does not apply to your skill, leave a one-line note explaining why.

### BEGIN TEMPLATE

```markdown
---
name: SKILL-DIRECTORY-NAME
description: >
  ONE-SENTENCE-PURPOSE. Use when SPECIFIC-TRIGGER-CONDITION-1, SPECIFIC-TRIGGER-CONDITION-2,
  or SPECIFIC-TRIGGER-CONDITION-3. Trigger when the user mentions KEYWORD-1, KEYWORD-2,
  or KEYWORD-3. Use for EDGE-CASE-THAT-SHOULD-STILL-TRIGGER.
allowed-tools:
  - Read
  - Glob
  - Grep
---

# SKILL HUMAN-READABLE TITLE

ONE-PARAGRAPH-PURPOSE. State what the skill does and what existing skill it
complements (or "stands alone" if none). Three sentences max.

## When to Use

- TRIGGER-CONDITION-1 (specific file shape, edit type, or domain phrase)
- TRIGGER-CONDITION-2
- TRIGGER-CONDITION-3
- TRIGGER-CONDITION-4
- TRIGGER-CONDITION-5

## When Not to Use

- NON-TRIGGER-CONDITION-1 — delegate to PEER-SKILL-NAME instead
- NON-TRIGGER-CONDITION-2 — out of scope per SCOPE-BOUNDARY
- NON-TRIGGER-CONDITION-3

---

## Reference Docs

| # | File | Read when… |
|---|------|-----------|
| 1 | [TOPIC-1.md](references/TOPIC-1.md) | SPECIFIC-SUBTASK-1 |
| 2 | [TOPIC-2.md](references/TOPIC-2.md) | SPECIFIC-SUBTASK-2 |
| 3 | [TOPIC-3.md](references/TOPIC-3.md) | SPECIFIC-SUBTASK-3 |

---

## OPTIONAL: Inline Quick-Reference

ONLY include this section if the skill has scannable, table-shaped content that
would force the reader to open a reference file just to look up a single value.
Common shapes: error-symptom→cause→fix grids, common-pitfalls tables, golden-rule
lists with no prose. If the content needs more than one paragraph of narrative,
move it to `references/` instead.

| Symptom | Cause | Fix |
|---------|-------|-----|
| EXAMPLE-SYMPTOM | EXAMPLE-CAUSE | EXAMPLE-FIX |

---

## Related Skills

- `PEER-SKILL-NAME` — ONE-LINE-DELEGATION-DESCRIPTION
- `OTHER-PEER-SKILL` — ONE-LINE-DELEGATION-DESCRIPTION
```

### END TEMPLATE

---

## Section-by-Section Notes

### Frontmatter `description` field

This is the **only** triggering surface. It loads in every Claude Code session
whether the skill fires or not. Optimize ruthlessly:

- 50–300 characters total. Below 50, the compliance checker rejects it; above 300,
  you are paying metadata cost in every session for content nobody reads.
- Lead with what the skill does (one sentence). Follow with explicit "Use when…" /
  "Trigger when…" phrases — these anchor semantic matching.
- Include concrete keywords users would actually type, not abstract category names.
  "writing PowerShell scripts" beats "shell scripting work".
- List edge cases the skill SHOULD trigger on but a literal reading might miss.

### Purpose paragraph

One paragraph, three sentences max. Establish what the skill does and where it sits
relative to peers. The four refactored skills all do this in 2–3 sentences:

- `python-architecture`: "Project structure, design patterns, and architectural
  decisions for maintainable Python applications. Complements the `python-core`
  skill which covers line-level coding standards."
- `nextjs-supabase`: "Production patterns for Next.js App Router applications with
  Supabase backend. Prevents silent auth failures, async state corruption, query
  errors, and environment drift."

### "When to Use" bullets

5–8 bullets. Each is a specific trigger condition — a file shape, an edit pattern,
a domain phrase. Avoid generic verbs ("working with X"). Prefer concrete actions
("Writing or reviewing route handler authentication with `getUser()`").

### "When NOT to Use" bullets

This section matters as much as "When to Use." It tells Claude when to delegate.
Each bullet should either:

- Name the peer skill that owns the case ("Generic React patterns with no Supabase
  involvement — delegate to a generic React skill if one exists"), or
- State an explicit out-of-scope boundary ("Database schema design or migration
  authoring — no migration patterns in this skill").

### Reference table

The load-bearing element. Three columns, exact format:

| Header | Content |
|--------|---------|
| `#` | Numeric, 1-indexed, monotonic |
| `File` | `[topic-name.md](references/topic-name.md)` markdown link |
| `Read when…` | A specific subtask phrase, ending with no period |

The "Read when…" column is the trigger surface for on-demand loading. Make it
specific enough that Claude can match a current subtask to a row at scan time.

### Inline quick-reference (optional)

Include only if the content is **scannable** — single table, single short list,
or single code snippet under 15 lines. The decision rule: if a reader needs to
*read* the section to extract value, it belongs in `references/`. If they can
*scan* it (find symptom, get fix), it belongs inline.

The four refactored skills demonstrate the pattern:

- `nextjs-supabase` keeps an 8-row error-symptom table inline (scannable)
- `python-core` keeps a 10-bullet "Key Principles" list inline (scannable)
- `python-architecture` keeps a 7-question "Architecture Decision Checklist" inline
  (scannable diagnostic)
- `powershell-windows` keeps an 8-row pitfall table + a 9-line file-path code block
  inline (scannable)

None of them keep narrative prose inline. That migrated.

### Related Skills

Cross-pointers to peer skills the reader might also want. Keep to 1–3 entries.
Each is `\`skill-name\`` — one-line delegation hint.

---

## Anti-Patterns

These are shapes the four refactors specifically *moved away from*. Do not
reintroduce them:

- **Long prose sections under H2 headers.** If a section has 3+ paragraphs of
  narrative, it belongs in `references/`.
- **Code examples >30 lines inline.** Move to `references/` or `scripts/` (use
  `scripts/` if the code is genuinely runnable, not just illustrative).
- **Multi-paragraph "philosophy" or "principles" sections.** A scannable list of
  10 single-sentence principles is fine; 10 paragraphs is not.
- **Inline TOC that duplicates the reference table.** The reference table IS the
  TOC. One source of truth.
- **"How to use this skill" meta-sections.** The frontmatter description and
  "When to Use" bullets cover this. Don't restate it in the body.
- **Step-by-step procedural walkthroughs** longer than 5 steps. Move to
  `references/<procedure>.md` and link from the reference table.

---

## Length Guidance

- Target SKILL.md body: 60–150 lines
- WARNING threshold (current): 150 lines
- ERROR threshold: 300 lines

These targets are calibrated against the refactor outcomes, not pulled
from thin air. The four refactored skills landed at 60, 96, 96, 97 lines. The five
existing well-formed skills (`peer-review`, `discord-webhook`, `technical-writing`,
`web-research`, `generate-deployment-prompt`) range 79–191. A new skill that exceeds
200 lines should justify the size in its PR description or refactor before merge.

---

## Cross-References

- See [modular-decomposition.md](modular-decomposition.md) for *when* to extract
  content from SKILL.md to `references/` (the heuristic this template assumes).
- See [token-cost-model.md](token-cost-model.md) for *why* this shape matters
  (the cost-of-loading framing that motivates progressive disclosure).
