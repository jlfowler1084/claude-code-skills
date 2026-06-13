---
name: technical-writing
description: >
  Use when creating or updating any project documentation: writing an ADR or
  design doc, adding or editing a registry/reference table, authoring a README,
  SKILL.md, runbook, or command doc, drafting a plan or brainstorm, or deciding
  which content type (conceptual, referential, procedural, troubleshooting) fits
  a new document. Also use when publishing documentation to Atlassian Confluence
  (page structure, Markdown-to-Confluence conversion, macros, space hierarchy).
  Trigger when the user says "write a doc", "create an ADR", "add a reference
  table", "draft a runbook", "what content type should I use", "publish this to
  Confluence", or starts editing a *.md documentation file. Do NOT use for
  source-code comments or docstrings (use a language skill), or for sentence-level
  prose/grammar polish (use a prose-style skill).
allowed-tools:
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Bash
---

# Technical Writing Skill

Structural decisions for project documentation. This skill owns **shape**: content
type selection, article structure, anti-patterns, and the house conventions of the
repository you are working in. It is platform-agnostic at its core, with a dedicated
reference for publishing to Atlassian Confluence.

Prose quality, grammar, and sentence-level style are out of scope -- delegate those to
a prose-style skill if one is installed (e.g. `elements-of-style:writing-clearly-and-concisely`
or `compound-engineering:every-style-editor`). CLAUDE.md / AGENTS.md audits delegate to a
project-memory skill (e.g. `claude-md-management:claude-md-improver`). If those skills are
not present in this environment, apply the structural rules below and leave prose polish
to the human reviewer.

---

## 1. When to Use This Skill

**Activate for:**
- Creating or editing documentation `*.md` files (`README*`, ADRs, registries/reference
  tables, `SKILL.md`, command docs, runbooks, plans, solution write-ups)
- Deciding which content type fits a document being drafted
- Adding or updating a registry / reference table
- Authoring or filing an ADR
- Writing a plan, brainstorm, or solution doc
- Publishing or converting documentation to Atlassian Confluence (see `references/confluence.md`)

**Do not activate for:**
- Source-code comments or docstrings -- governed by the relevant language skill
- Marketing copy, academic papers, release blog posts
- CLAUDE.md / AGENTS.md edits -- use a project-memory skill
- Prose sentence-level review -- use a prose-style skill

---

## 2. Content-Type Taxonomy

Select by what the reader needs to accomplish, not by document length.

*Borrowed from sjungling/claude-plugins technical-writer skill. Attribution: Steven Jungling (https://github.com/sjungling/sjungling-claude-plugins).*

| Type | Reader Need | Typical Examples | Key Marker |
|------|------------|------------------|------------|
| **Conceptual** | Understand why or how something works | ADRs, architecture docs, brainstorms | Explains decisions, context, trade-offs |
| **Referential** | Look up a value, command, or schema | Registries, config references, API tables | Tables, lists, parameter specs |
| **Procedural** | Follow steps to complete a task | Runbooks, HOWTOs, SKILL operating steps | Numbered steps, imperative verbs |
| **Troubleshooting** | Diagnose and fix a known problem | Solution entries, incident write-ups | Symptom -> Cause -> Fix structure |
| **Quickstart** | Get working in under 5 minutes | Onboarding notes, first-run instructions | Max 5 steps, max 600 words |
| **Tutorial** | Learn by doing with a guided example | Walkthroughs | Narrative, follows one scenario end-to-end |
| **Release Notes** | Know what changed and why | Changelogs, version notes | Version-anchored, past tense |

**Selection rule:** One doc, one primary type. If a document needs two types, split it or
make one a subsection that you label ("Background" for conceptual within a procedural doc).

---

## 3. Article-Element Checklist

Every document must have a clear entry and exit. Missing elements are the most common
cause of doc rot -- readers skip docs that don't answer "what is this for?" in the first
paragraph.

Use this checklist when creating or reviewing any doc:

- [ ] **Title** -- noun phrase that names the subject, not the action (e.g., "Hooks Registry", not "How hooks work")
- [ ] **Intro / Purpose** -- one paragraph: what this doc is, who it is for, what it covers
- [ ] **Prerequisites** -- what the reader must have or know first (omit only if none)
- [ ] **Permissions / Access** -- if the task requires elevation or special access (omit if not applicable)
- [ ] **Main content** -- the body: steps, tables, reference data, or explanation per the content type
- [ ] **Troubleshooting** -- embedded as a section or linked to a dedicated solution doc
- [ ] **Next steps** -- where to go after completing this doc (omit only if the doc is a dead-end reference)

For registries (referential type), the checklist condenses to: Title + `Last updated:` header + table + notes section if needed.

---

## 4. Procedural Ordering and Quickstart Limits

### Procedural Ordering

When a document covers multiple lifecycle phases for a feature, order sections as:

1. **Enabling** -- turning the feature on, installation, registration
2. **Using** -- the normal operational flow
3. **Managing** -- configuration, tuning, monitoring
4. **Disabling** -- turning off cleanly, deregistering
5. **Destructive** -- deleting data or breaking changes (always last)

Never put destructive or disabling steps before enabling steps. Readers scan top-to-bottom
and may act before finishing.

*Ordering rule borrowed from sjungling/claude-plugins technical-writer skill.*

### Quickstart Hard Limits

A document titled "Quickstart" or "Getting started" MUST obey:
- **5 minutes** to complete all steps
- **600 words** maximum total length
- **5 steps or fewer** in the main procedure

If the content exceeds these limits, it is a Tutorial, not a Quickstart.

---

## 5. House Rules -- Customize Per Repository

The rules in this section encode repository-specific conventions. **They are placeholders.**
Replace the bracketed values with the conventions of the repo you are working in, then commit
the customized skill alongside that repo (or to your runtime skills directory). The *principles*
are portable; the *values* are not.

> Customization tip: when you land this skill in a new environment, do one pass through R1-R6,
> filling in the bracketed `[...]` fields. Delete any rule that does not apply.

### R1: Source-of-Truth Hierarchy

Identify which directory is canonical and which is a generated/deployed copy, then never edit
the generated copy by hand.

- Canonical source: `[e.g. configs/, src/docs/]`
- Generated / deployed copy: `[e.g. ~/.claude/, a published site, a Confluence space]`
- Regeneration command: `[e.g. the deploy/build script]`

Edits to a generated copy are silently overwritten on the next regeneration. Always edit the
canonical source, commit, then regenerate.

### R2: ADR Naming and Citation

If the repo uses Architecture Decision Records, fix one naming convention and enforce it.

- Location + pattern: `[e.g. docs/decisions/NNNN-short-title.md, zero-padded sequence]`
- Every ADR cited in a decision log must exist as a file at that path.
- Short title is kebab-case, no more than ~5 words.

### R3: Per-Registry / Per-Reference Schema Stability

Each reference table has a stable, per-table column schema. Do not invent new columns ad hoc.

- Every registry / reference file should carry a `Last updated: YYYY-MM-DD` line immediately
  after the title, before any table.
- The column schema is determined by the table's content -- there is no universal default.
- If a new column is genuinely needed, update the `Last updated:` date and note the schema
  change in a "Schema notes" section below the table.

### R4: Encoding and Pipeline Constraints

Know the encoding limits of every pipeline a document passes through before you write it.

- Default to UTF-8. Prefer plain hyphens (`-`) or double-hyphen (`--`) over em-dashes (U+2014)
  unless you have confirmed every downstream tool preserves them.
- If a deploy/convert step is known to corrupt characters (em-dashes, box-drawing glyphs,
  smart quotes), avoid those characters in source: `[note any such pipeline here]`.
- For Confluence, mind storage-format/XHTML escaping of `<`, `>`, and `&` -- see
  `references/confluence.md`.
- Verify after writing with a grep for the offending bytes, e.g.
  `grep -rP '\xe2\x80\x94' <path>` to confirm absence of em-dashes.

### R5: Tool / Component Documentation Contract

Every shipped tool or component must be discoverable in documentation, in one of two forms:

1. **Registry row** -- a row in the relevant reference table naming the component, its location,
   and its purpose.
2. **Per-component README** -- a `README.md` describing the component, its parameters, and usage.

Undocumented components are indistinguishable from abandoned ones. An unreferenced tool with no
README is documentation rot.

### R6: Composition Over Duplication

This skill owns structural decisions. Delegate the following to their owners when those skills
exist in the environment; otherwise, hand the concern to the human reviewer. Do not copy their
rules in here.

| Concern | Delegate To (if installed) |
|---------|---------------------------|
| Prose grammar and style | a prose-style skill (e.g. `elements-of-style:writing-clearly-and-concisely`) |
| Line-by-line review | a copy-edit skill (e.g. `compound-engineering:every-style-editor`) |
| CLAUDE.md / AGENTS.md audits | a project-memory skill (e.g. `claude-md-management:claude-md-improver`) |

---

## 6. Anti-Patterns

*Borrowed verbatim from sjungling/claude-plugins technical-writer skill. Attribution: Steven Jungling (https://github.com/sjungling/sjungling-claude-plugins).*

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| **Wall of text** | No visual entry points; readers skip | Add headers, bullets, or a table |
| **Step zero missing** | Readers fail at unlisted prerequisites | Add a Prerequisites section |
| **Vague titles** | "Overview" or "Notes" says nothing | Use noun phrases that name the subject |
| **Mixed types** | One doc tries to be reference + tutorial | Split into two docs or label subsections by type |
| **Orphaned docs** | File exists but nothing links to it | Add a link from the parent registry or index |
| **Stale tables** | Registry rows with wrong paths or removed components | Update `Last updated:` and audit rows against disk |
| **Undefined acronyms** | TLA used without introduction | Spell out on first use: "ADR (Architecture Decision Record)" |
| **Imperative in headings** | "How to deploy" vs "Deployment" | Use noun phrases; save imperative for step text |
| **No exit** | Doc ends mid-procedure with no "Next steps" | Add a brief "Next steps" or "See also" section |
| **Universal registry columns** | Inventing new columns across tables | Honor per-table schema; note changes explicitly |

---

## 7. Self-Check Workflow

Before committing any documentation change, run the bundled structural validator. It is a
standalone PowerShell 7 script with no repository-specific dependencies.

```powershell
# Check a single file
pwsh scripts/Test-MarkdownStructure.ps1 -Path README.md

# Check multiple files
Get-ChildItem docs/ -Filter '*.md' -Recurse |
    pwsh scripts/Test-MarkdownStructure.ps1

# Save a JSON report
pwsh scripts/Test-MarkdownStructure.ps1 -Path README.md -ReportPath "$env:TEMP\structure-report.json"
```

Exit codes:
- `0` -- no structural issues found
- `1` -- structural failures (heading gaps, broken links, or unbalanced code fences)
- `2` -- invocation error (file not found, missing arguments)

**What the validator checks:**
- Heading-level monotonicity: h1 -> h3 with no h2 is a failure
- Local link targets: `[text](path)` where `path` is a relative file path that does not exist
- Code-fence balance: odd count of triple-backtick fences indicates an unclosed block

**What it does not check:**
- Prose quality (use a prose-style skill)
- Reference-row completeness against reality (a separate audit job)
- YAML frontmatter validity

> The validator is Windows / PowerShell 7 (`pwsh`) oriented and optional. If your environment
> has no PowerShell, treat the three checks above as a manual review checklist, or port the
> logic to your tooling of choice. Tests live in `scripts/Test-MarkdownStructure.Tests.ps1`
> (Pester 5).

---

## 8. Publishing to Atlassian Confluence

When the destination is Confluence rather than a Markdown file in the repo, read
`references/confluence.md`. It covers:

- The Markdown -> Confluence storage-format / ADF mapping (and what does not round-trip)
- Page hierarchy and space organization decisions
- Common macros (info/note/warning panels, code blocks, table of contents, expand)
- The author-in-Markdown, sync-to-Confluence workflow and the tooling options
- A pre-publish checklist that layers on top of the §3 article checklist

The content-type taxonomy (§2) and article checklist (§3) apply unchanged -- Confluence is a
rendering target, not a different kind of writing.
