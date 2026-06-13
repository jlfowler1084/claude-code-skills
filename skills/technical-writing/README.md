# Technical Writing Skill

A Claude Code skill for the **structure** of project documentation -- choosing the right
content type, satisfying an article checklist, ordering procedures safely, avoiding the
common anti-patterns, and publishing to Atlassian Confluence. It owns shape, not prose
polish; sentence-level grammar and style delegate to a dedicated prose-style skill if one
is installed.

This is a generalized, environment-agnostic port. The repository-specific conventions live
in a clearly marked **"House Rules"** section of `SKILL.md` as fill-in placeholders -- you
customize them once per environment.

## What This Skill Does

- **Content-type taxonomy** -- pick one primary type (conceptual, referential, procedural,
  troubleshooting, quickstart, tutorial, release notes) per document.
- **Article-element checklist** -- every doc has a clear entry (purpose, prerequisites) and
  exit (next steps), so readers don't bounce off it.
- **Procedural ordering + quickstart limits** -- enabling before destructive; quickstarts
  capped at 5 steps / 600 words / 5 minutes.
- **Anti-pattern catalog** -- wall of text, vague titles, orphaned docs, stale tables, and
  how to fix each.
- **Confluence publishing** -- `references/confluence.md` covers the Markdown-to-Confluence
  mapping, page hierarchy, macros, and the author-in-Markdown / sync-to-Confluence workflow.
- **Structural validator** -- a standalone PowerShell 7 script (`scripts/`) that checks
  heading hierarchy, local-link targets, and code-fence balance, with a Pester test suite.

## Layout

```
technical-writing/
  SKILL.md                         # the skill (structure rules + house-rule placeholders)
  references/
    confluence.md                  # Markdown -> Confluence publishing reference
  scripts/
    Test-MarkdownStructure.ps1     # standalone structural validator (pwsh 7)
    Test-MarkdownStructure.Tests.ps1  # Pester 5 suite (12 tests)
    fixtures/                       # pass/fail markdown fixtures for the tests
```

## Installation

```bash
# Global (all projects)
cp -r skills/technical-writing ~/.claude/skills/technical-writing

# Per-project
cp -r skills/technical-writing .claude/skills/technical-writing
```

PowerShell:

```powershell
# Global
Copy-Item -Recurse skills/technical-writing $HOME/.claude/skills/technical-writing
```

## Customize for Your Environment

Do one pass through `SKILL.md` section 5 ("House Rules -- Customize Per Repository") and fill
in the bracketed `[...]` fields for the repo you are working in:

- **R1** Source-of-truth vs generated-copy directories, and the regeneration command
- **R2** ADR location and naming pattern (delete if you do not use ADRs)
- **R3** Registry / reference-table schema conventions
- **R4** Encoding constraints of your publish pipeline (and Confluence escaping)
- **R5** The tool/component documentation contract
- **R6** Which prose-style and project-memory skills (if any) to delegate to

Delete any rule that does not apply. Commit the customized skill alongside the target repo.

## Confluence Setup

If you publish to Confluence, read `references/confluence.md` first. The short version:

- Author in Markdown (source of truth in git), sync to Confluence with a converter.
- Recommended converter for a Windows / PowerShell + git shop: **`mark`** (kovetskiy/mark) --
  a single Go binary that does idempotent create-or-update and uploads image attachments.
- Confirm whether your Confluence is **Cloud** (ADF / REST v2) or **Data Center** (storage
  format / REST v1) before configuring tooling.
- Never hardcode the Confluence API token -- source it from an environment variable or your
  secret manager.

## Running the Validator

```powershell
# Single file
pwsh skills/technical-writing/scripts/Test-MarkdownStructure.ps1 -Path README.md

# Whole docs tree
Get-ChildItem docs/ -Filter '*.md' -Recurse |
    pwsh skills/technical-writing/scripts/Test-MarkdownStructure.ps1

# Run the test suite (requires Pester 5)
Invoke-Pester skills/technical-writing/scripts/Test-MarkdownStructure.Tests.ps1
```

Exit codes: `0` clean, `1` structural issues, `2` invocation error.

## Attribution

The content-type taxonomy, procedural-ordering rule, and anti-pattern catalog are adapted
from the sjungling/claude-plugins technical-writer skill by Steven Jungling
(https://github.com/sjungling/sjungling-claude-plugins).
