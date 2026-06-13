# Modular Decomposition Heuristics

When to extract content from SKILL.md to `references/` — and when to leave it
inline. Every claim here is grounded in what a set of real skill refactors
actually did, not theoretical best practice.

This is the *judgment* part of skill authoring. Most decisions are obvious; the
hard cases live at the boundaries this doc addresses.

---

## The Core Rule

**Read vs scan.** If the content needs to be *read* to extract value, it belongs
in `references/`. If it can be *scanned* (find symptom, get fix), it belongs
inline.

Everything below elaborates this single rule against concrete evidence.

---

## Extraction Triggers

A topic earns extraction to `references/<topic>.md` when **any** of the following
applies. Multiple triggers are not required — a single one is sufficient.

### Trigger 1: 3+ subheadings on the same topic

If a section has three or more H3 subheadings under one H2, the topic is broad
enough to deserve its own file.

**Evidence (`python-architecture`):**
The original SKILL.md had a single H2 "Repository Pattern" with H3 subheadings for
"Protocol-based abstraction", "In-memory fakes for tests", "SQLAlchemy adapter",
and "Async repositories". Four subheadings → extracted to
`references/repository-pattern.md`. Reader who only needs the protocol pattern can
load just that file; reader doing a full review can load all four sub-pattern
files.

**Counter-example (`python-core`):**
The "Key Principles" section had no subheadings — it's a flat list of 10 numbered
principles. Stayed inline because subheadings = topical depth, and a flat list
has no depth to extract.

### Trigger 2: Code blocks total >30 lines

Once a section's code blocks (cumulatively) exceed 30 lines, the section is doing
"show me the code" work, not skill-trigger work.

**Evidence (`powershell-windows`):**
The original "Advanced Functions" section contained four code blocks totaling
~80 lines (CmdletBinding examples, OutputType variations, parameter set patterns,
pipeline input handling). Extracted to `references/advanced-functions.md`. The
SKILL.md body now references the file in a single table row.

**Counter-example (same skill):**
The inline "File Paths" code block kept in the trimmed SKILL.md is 9 lines —
under threshold and high-frequency lookup. It stayed inline.

### Trigger 3: Standalone reference table

A table that the reader looks up against (rather than reads through) often
deserves its own file *if* it has more than ~10 rows or requires column-by-column
reading.

**Evidence (`nextjs-supabase`):**
The query-pattern reference table had 14 rows covering `.from()`, `.select()`,
`.insert()`, `.upsert()`, `.rpc()`, `.maybeSingle()`, RLS policy patterns, etc.
Extracted to `references/query-patterns.md` because each row needed a paragraph
of context, not just symptom→fix.

**Counter-example (same skill):**
The 8-row "Common Error Patterns" table (symptom→cause→fix) stayed inline. Each
row is a single tight match — no surrounding context needed. The reader scans for
their symptom and gets a fix in one row.

### Trigger 4: Useful to read independently

Could a reader land on this content via a search result and get value without
the surrounding skill context? If yes, it stands alone — extract it.

**Evidence (`python-architecture`):**
The "SOLID principles" content was framed as Python-specific examples of SRP,
OCP, LSP, ISP, DIP. Extracted to `references/solid-principles.md` because someone
arriving from a "SOLID in Python" search query gets useful content without
needing the architecture-skill framing. Same logic applied to "Domain Modeling",
"Configuration", "Testing Patterns".

**Counter-example (same skill):**
The "Architecture Decision Checklist" (7 diagnostic questions) stayed inline.
The questions are *only* useful in the flow of designing a new module — they have
no standalone meaning. Reading them out of context produces no value.

---

## What Stays Inline

The refactored skills converged on a small, repeatable set of inline shapes.
If your content fits one of these shapes, **keep it inline**:

### Shape 1: Quick-reference tables

Single tables where the reader looks up symptom or context and gets a tight
answer. Maximum ~10 rows. Each row is self-contained — no paragraph of context.

| Refactor | What stayed inline |
|----------|---------------------|
| `nextjs-supabase` | 8-row error-pattern table (symptom → cause → fix) |
| `powershell-windows` | 8-row pitfall table (error message → cause → fix) |

### Shape 2: Diagnostic checklists

Numbered question lists that drive a decision. Each question is one line. No
explanatory prose between questions.

| Refactor | What stayed inline |
|----------|---------------------|
| `python-architecture` | 7-question "Architecture Decision Checklist" |

### Shape 3: Flat principle lists

A flat list of single-sentence principles, no subheadings, no nesting.

| Refactor | What stayed inline |
|----------|---------------------|
| `python-core` | 10-bullet "Key Principles" list |

### Shape 4: Single small code block (<15 lines)

Illustrative code that demonstrates *one* concept and does not warrant a full
reference file.

| Refactor | What stayed inline |
|----------|---------------------|
| `powershell-windows` | 9-line "File Paths" code block |

### Shape 5: One-line golden rule with table

A single load-bearing rule that the rest of the skill orbits around, often
followed by a 2–4 row decision table.

| Refactor | What stayed inline |
|----------|---------------------|
| `python-core` | "Golden Rule: New Code vs Existing Code" + 4-row decision table |

---

## What Moves to `scripts/` Instead of `references/`

`references/` is for content (markdown, prose, examples). `scripts/` is for
runnable code that the skill *invokes* — not illustrates.

The decision rule:

- **Illustrative code** (showing what a pattern looks like) → `references/`
- **Runnable code** (validators, generators, wrappers, entry points) → `scripts/`

**Example:** a skill that performs an automated review might keep its runnable
review scripts (an entry point plus any helpers it calls) in `scripts/`. Those
are not referenced from the SKILL.md body as illustrations — they are *invoked*
by the skill's procedure. That is the correct use of `scripts/`.

If your skill's extracted content is prose patterns rather than runnable code, it
won't produce `scripts/` content at all. Only add `scripts/` if the skill
genuinely ships executable tooling.

---

## Anti-Patterns to Avoid

### Anti-pattern 1: Splitting too aggressively

A `references/` file under ~30 lines is usually a sign of premature extraction.
The reader pays a load-cost (separate file fetch, separate context turn) for
content that could have stayed inline. Healthy reference files land in the
80–400 line range; nothing under 50.

**Rule of thumb:** if extracting a section produces a `references/` file under
50 lines, it probably belongs inline.

### Anti-pattern 2: Splitting too coarsely

A `references/<topic>.md` file over ~400 lines just shifts the bloat — the
reader still pays for a long load when they trigger that topic. If a reference
file approaches 400 lines, split it further.

**Evidence:** `python-core`'s `references/error-handling.md` was originally
drafted around 600 lines covering exception hierarchies, scoping, fallback
chains, and async error patterns in one doc. Split into `error-handling.md`
(~250 lines) and `async-patterns.md` (~200 lines) before merge.

### Anti-pattern 3: Inlining narrative prose

If a section has 3+ paragraphs of narrative explanation, it does not pass the
"scan, don't read" test. Move it.

### Anti-pattern 4: Duplicating content between SKILL.md and `references/`

The reference table in SKILL.md is a TOC pointing at extracted content. Do not
restate the extracted content in SKILL.md as a "summary" — the reference's
existence is enough. One source of truth.

### Anti-pattern 5: Stub references with no extracted body

Creating `references/<topic>.md` files that are themselves under 30 lines or just
restate what's in SKILL.md. Avoid this in new authoring.

---

## Decomposition Worked Example: `python-architecture`

Concrete walk-through of how one refactor applied these heuristics.

**Original SKILL.md** (500 lines): single document covering SOLID, layered
architecture, repository pattern, service layer, domain modeling, configuration,
testing, and a decision checklist. All inline.

**Refactor pass:**

1. Identified topical sections by scanning H2 headers: 8 distinct topics.
2. Applied Trigger 1 (3+ subheadings) — 6 of 8 sections had 3+ H3s. Extract.
3. Applied Trigger 2 (code volume) — 7 of 8 sections had >30 lines of code. Extract.
4. Applied Trigger 4 (standalone value) — every "pattern" topic (Repository,
   Service Layer, Domain Modeling) reads usefully out of context. Extract.
5. Applied "what stays inline" Shape 2 (diagnostic checklist) to the
   "Architecture Decision Checklist" section. Keep inline.
6. Applied "what stays inline" Shape 1 (small reference table) to the introductory
   "When to Use" / "When Not to Use" — these are not technically tables but
   bullet lists serve the same scan-don't-read function.

**Outcome:** SKILL.md trimmed to 96 lines. Eight `references/` files created
(greenfield-vs-brownfield, project-layout, solid-principles, domain-modeling,
repository-pattern, service-layer, configuration, testing-patterns), each in the
80–250 line range. One inline diagnostic checklist (Shape 2). Zero content lost.

This is the pattern to copy. It is also the shape encoded in
[thin-skill-template.md](thin-skill-template.md).

---

## Cross-References

- See [thin-skill-template.md](thin-skill-template.md) for the resulting SKILL.md
  shape after applying these heuristics.
- See [token-cost-model.md](token-cost-model.md) for the cost framing that
  motivates extraction in the first place.
