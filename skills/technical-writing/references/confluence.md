# Publishing to Atlassian Confluence

Reference for the `technical-writing` skill. Read this when the documentation target is a
Confluence page instead of (or in addition to) a Markdown file in the repository.

The structural discipline in `SKILL.md` still applies: pick one content type (SKILL.md
section 2), satisfy the article checklist (section 3), follow procedural ordering
(section 4). Confluence is a **rendering and storage target**, not a different kind of
writing. This reference covers only what changes when the destination is Confluence.

> Recommended workflow for this environment: **author in Markdown, sync to Confluence.**
> Markdown stays the source of truth in git; a converter pushes pages to Confluence. You
> get version control, diff review, and the structural validator, while Confluence stays
> current.

---

## 1. Confluence Does Not Store Markdown

Confluence has never stored Markdown natively. Know which underlying format you are
targeting, because it determines which converter and API version you use.

| Format | Where it is used | Shape |
|--------|------------------|-------|
| **Storage format** | Confluence Server / Data Center; still accepted by Cloud REST v1 | XHTML-based XML with `<ac:...>` macro elements |
| **ADF** (Atlassian Document Format) | Confluence Cloud REST API v2 | JSON node tree |
| **Wiki markup** | Legacy editor input only | `h1.`, `{code}`, `{info}` -- deprecated, do not author new docs in it |
| **Markdown** | Editor *import* and the `{markdown}` macro only | Converted on paste; not a storage format |

**Implication:** you do not paste Markdown and get a clean page. You run a converter that
maps Markdown to storage format or ADF and calls the REST API. Cloud sites lean ADF / REST
v2; Server and Data Center use storage format / REST v1. Confirm which one your Confluence
instance is before choosing tooling.

---

## 2. Markdown -> Confluence Mapping

What round-trips cleanly and what needs attention:

| Markdown | Confluence result | Notes |
|----------|-------------------|-------|
| Headings `#`..`######` | Native headings | Heading hierarchy still matters; the validator catches gaps |
| Paragraphs, bold, italic, inline code | Native | Clean |
| Bulleted / numbered lists | Native lists | Nested lists round-trip |
| Tables (GFM pipe tables) | Native tables | Complex cell content can be lossy; keep cells simple |
| Fenced code ```` ```lang ```` | **Code Block macro** | Language label preserved if the converter sets it (see section 4) |
| Links `[t](url)` | Hyperlinks | **Relative repo links break** -- see section 5 |
| Images `![](path)` | Attached images or external `<img>` | Local images must be uploaded as page attachments by the converter |
| Blockquotes `>` | Quote block | Often better expressed as an info/note panel macro |
| Front matter (`---` YAML) | Stripped or consumed as metadata | Converters read Space/Title/Parent from front matter; it never renders |
| Task lists `- [ ]` | Confluence task list | Support varies by converter |
| Horizontal rule `---` | Divider | Fine |

Does **not** exist in Markdown and must be added as a macro if you want it: expand/collapse
sections, info/note/warning panels, table of contents, status lozenges, Jira issue links,
page-children listings (see section 4).

---

## 3. Page Hierarchy and Spaces

Decide structure before publishing -- moving pages later breaks links and notifications.

- **Space**: the top-level container, identified by a **space key** (e.g. `ENG`, `DOCS`).
  One space per product, team, or knowledge domain.
- **Parent page**: every page except the space home has a parent. The parent tree is the
  navigation. Choose the parent deliberately; orphaned pages are as bad as orphaned Markdown.
- **Page title**: titles must be **unique within a space**. A converter that "creates by
  title" will update an existing page if the title matches -- intended for idempotent sync,
  but a duplicate title elsewhere will collide. Title your docs specifically.
- **Labels**: Confluence labels are the registry/index mechanism. Apply consistent labels
  so pages are findable; they are the Confluence analogue of a reference table's rows.

Map your repo layout to the page tree intentionally. A common pattern: one parent page per
top-level docs folder, child pages per document, mirroring the directory structure.

---

## 4. Common Macros

Macros are the Confluence features with no Markdown equivalent. The converters in section 6
expose these through fenced-block or directive syntax; check your converter's docs for the
exact spelling. The ones worth knowing:

| Macro | Purpose | When to use |
|-------|---------|-------------|
| **Info / Note / Tip / Warning panel** | Colored callout box | Prerequisites, gotchas, "do not do X" warnings |
| **Code Block** | Syntax-highlighted code with language + optional title | All code samples; set the language for highlighting |
| **Table of Contents** (`toc`) | Auto-generated from headings | Any page longer than one screen |
| **Expand** | Collapsible section | Long reference output, optional detail, troubleshooting dumps |
| **Children Display** (`children`) | Lists child pages | Index / landing pages that front a page tree |
| **Status** | Colored lozenge (e.g. green "DONE") | Status columns in reference tables |
| **Jira** | Live-rendered Jira issue link/table | Linking docs to tickets |

Panels replace Markdown blockquotes for anything that is genuinely a callout. A `> Note:`
blockquote reads better in Confluence as an info panel.

---

## 5. Links, Attachments, and Escaping

Three things that silently break on publish:

1. **Relative repo links.** `[setup](../setup/README.md)` is meaningless in Confluence. Either
   let the converter rewrite repo-relative links to Confluence page links (the better
   converters do this by matching titles/paths), or use absolute Confluence URLs. Audit every
   relative link before publishing.
2. **Local images.** `![diagram](./img/flow.png)` requires the converter to upload `flow.png`
   as a page attachment and rewrite the reference. If your converter does not upload
   attachments, host the image elsewhere and use an absolute URL.
3. **Storage-format escaping.** If you target storage format (Server / Data Center), raw `<`,
   `>`, and `&` in text must be XML-escaped (`&lt;`, `&gt;`, `&amp;`). Converters handle this,
   but hand-written storage-format snippets or `{markdown}`-macro content can break a page if
   unescaped. This is the Confluence instance of `SKILL.md` rule R4 (encoding constraints).

---

## 6. Author-in-Markdown, Sync-to-Confluence Tooling

Pick one converter and standardize on it. All of these keep Markdown as the source of truth
and push to Confluence via the REST API. **Do not hardcode credentials** -- every option below
reads an API token from an environment variable (SKILL.md security posture: secrets stay in
env / a vault, never in the skill or the doc).

| Tool | Stack | Strengths | Metadata mechanism |
|------|-------|-----------|--------------------|
| **`mark`** (kovetskiy/mark) | Single Go binary | Mature, fast, macro support, attachment upload, Cloud + DC | HTML-comment headers: `<!-- Space: ENG -->`, `<!-- Title: ... -->`, `<!-- Parent: ... -->` |
| **`md2cf`** | Python (`pip install md2cf`) | Simple, scriptable, good for CI; pairs well with a Python shop | CLI flags or front matter |
| **`@markdown-confluence/cli`** | Node | Cross-platform, also ships an Obsidian plugin | YAML front matter (`connie-*` keys) |

Recommendation for a Windows + PowerShell shop publishing from git: **`mark`** -- one binary,
no runtime to manage, idempotent create-or-update by title, and it uploads image attachments.
Confirm against your actual Confluence flavor (Cloud vs Data Center) and your team's existing
conventions before committing; the work environment may already standardize on one.

Typical sync command shape (illustrative -- read your converter's docs for exact flags):

```powershell
# Token comes from the environment, never from the file or this skill
$env:CONFLUENCE_API_TOKEN = '<set this from your vault / secret manager>'

mark -u you@example.com `
     --base-url https://your-org.atlassian.net/wiki `
     -f docs/runbooks/deploy.md
```

In CI, the same command runs on merge to the default branch so Confluence tracks the repo.

---

## 7. Pre-Publish Checklist

Layer this on top of the `SKILL.md` section 3 article checklist:

- [ ] Content type chosen and the page matches it (section 2 of `SKILL.md`)
- [ ] Heading hierarchy has no gaps (run `scripts/Test-MarkdownStructure.ps1`)
- [ ] Every relative repo link rewritten to a Confluence link or absolute URL
- [ ] Local images will be uploaded as attachments (or replaced with absolute URLs)
- [ ] Space key and parent page chosen; title is unique within the space
- [ ] Callouts expressed as panels, not bare blockquotes, where they are genuinely callouts
- [ ] Long pages have a Table of Contents macro
- [ ] Labels applied for findability
- [ ] API token sourced from env / vault, not hardcoded
- [ ] Confluence flavor (Cloud / Data Center) confirmed and the converter configured for it

---

## 8. See Also

- `SKILL.md` sections 2-4 -- content types, article checklist, ordering (apply unchanged)
- `SKILL.md` section 5 R4 -- encoding constraints (storage-format escaping is the Confluence case)
- `scripts/Test-MarkdownStructure.ps1` -- structural validation before publish
