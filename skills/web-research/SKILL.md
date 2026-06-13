---
name: web-research
description: |
  Conduct genuine multi-source research on the open web with citation discipline. Use this skill when the user asks to research a topic, compare options, find authoritative sources, survey current state, investigate "what people are saying about", or do anything that requires synthesizing across multiple web pages. Routes through a tiered stack — a two-engine search layer (Tavily for keyword/recency, Exa for neural/semantic) escalating to Firecrawl scrape and built-in WebFetch — for quota efficiency, and applies a research methodology (query decomposition, source triage, cross-source triangulation, dated citations) rather than just dumping search results. Do NOT use for: scraping a single known URL (use Firecrawl directly), looking up library docs (use Context7), or quick factual lookups answerable from training data.
allowed-tools:
  - Bash(python *)
  - Bash(firecrawl *)
  - Bash(jq *)
  - Bash(mkdir *)
  - Bash(wc *)
  - Bash(head *)
  - Bash(grep *)
  - WebFetch
---

# web-research

Methodology + tiered routing for substantive web research. Wraps a two-engine
search layer (Tavily + Exa) and a Firecrawl scrape escalation with a research
discipline layer on top.

## When to use

**Triggers:** "research X", "what's the current state of X", "compare X and Y", "find authoritative sources on X", "what are people saying about X", "survey the literature on X".

**Do NOT use for:**
- Single-URL scraping → `firecrawl scrape <url>` directly (Tier 2)
- Library/framework docs → Context7 MCP
- Recently-cached factual lookups → answer from training data
- Internal codebase questions → `Grep` / `Glob`

## Tiered routing

| Tier | Tool | When to use |
|------|------|-------------|
| 1a | **Tavily search** | **Default.** Keyword/recency search + page markdown + a synthesized answer in one call. Best for "current state", news, and direct factual questions. |
| 1b | **Exa search** | **Neural/semantic.** Best for "find sources *like* this", concept discovery, niche/long-tail content, and research papers — anywhere the right keywords are hard to express. Also the better second engine for triangulating a different result set. |
| 2 | **Firecrawl scrape** | A specific URL a Tier-1 engine returned with thin/empty content (paywall, JS-rendered SPA, login wall). |
| 3 | **Built-in WebFetch** | Final fallback if the search APIs fail or are exhausted. |

**Choosing between Tavily and Exa:** start with Tavily for most queries. Reach for
Exa when the query is conceptual rather than keyword-shaped, when Tavily's results
are off-target, or when you want a second independent result set to triangulate
against. For an important breadth pass, run both in parallel and merge.

**Quota check before any call:**

```bash
firecrawl --status                          # Firecrawl credits remaining
# Tavily quota: https://app.tavily.com/home   (no CLI status)
# Exa quota:    https://dashboard.exa.ai      (no CLI status)
```

If Firecrawl credits are below 20%, refuse Tier 2 escalation and fall straight to Tier 3 instead.

## Research methodology

Apply this every time, not just for big tasks. The skill exists to enforce the discipline, not to skip it.

### 1. Decompose the question

Before any search, break the user's prompt into 2–4 sub-queries that cover different angles. A prompt like "research how teams are using Claude Code skills in production" decomposes into:

- "claude code skills production usage 2026"
- "claude code skills failures common pitfalls"
- "anthropic skills marketplace adoption metrics"
- "claude code skills vs MCP servers tradeoffs"

Search each sub-query separately. Single-query research produces single-source bias.

### 2. Run the search layer in parallel

```bash
mkdir -p .research
# Tavily for keyword/recency breadth
python ~/.claude/skills/web-research/tools/tavily-search.py "sub-query 1" \
  --max-results 5 --time-range month -o .research/q1-tavily.json &
# Exa for semantic / "find similar" coverage of the same angle
python ~/.claude/skills/web-research/tools/exa-search.py "sub-query 1" \
  --num-results 5 --type auto -o .research/q1-exa.json &
wait
```

Always write to `.research/` (or `.firecrawl/` for tier 2). Never read entire result blobs into context — use `jq` to extract URLs, titles, and scores first:

```bash
jq -r '.results[] | "\(.score)\t\(.title)\t\(.url)"' .research/q1-tavily.json | sort -rn
jq -r '.results[] | "\(.score)\t\(.title)\t\(.url)"' .research/q1-exa.json    | sort -rn
```

### 3. Triage by source reputation

Not all results are equal. Rank by these signals **before** consuming page content:

- **Primary sources** (official docs, GitHub repos, vendor blogs, RFCs) > secondary (Medium, dev.to, blog aggregators).
- **Author authority** — known practitioner > anonymous SEO content.
- **Recency** — for "current state" queries, anything > 12 months old is suspect.
- **Engine score** — relevance signal, not authority. Use as a tiebreaker, not a ranker. (Tavily and Exa score differently; don't compare scores across engines.)

Discard results that fail triage before reading their content. This is the single biggest context-window win.

### 4. Cross-check claims

A claim that appears in only one source is a hypothesis, not a fact. Before reporting anything as definitive:

- Find the same claim in ≥2 independent sources, OR
- Mark it explicitly as "per [source]" and let the user judge, OR
- Flag the disagreement: "Source A says X, source B says Y."

Two engines help here: a claim that surfaces in both Tavily and Exa result sets is better-corroborated than one that appears in only one.

### 5. Cite with discipline

Every factual claim in the final synthesis must carry: **[Source title](URL) — YYYY-MM-DD**. If you cannot find a publication date, write `(date unknown)` — never guess.

For tasks that produce a written deliverable (report, comparison, recommendation), end with a `## Sources` section listing every URL consumed, grouped by sub-query.

## Tier 2 escalation pattern

When a Tier-1 engine returns a high-relevance URL but the page content is thin/empty:

```bash
firecrawl scrape "https://example.com/dense-spa-page" \
  -o .firecrawl/$(date +%s)-page.md
```

Common Tier 1 failures that warrant Tier 2:
- React/Vue/Next.js SPAs with client-side rendering
- Pages behind soft paywalls (NYT, Bloomberg, Substack)
- Long-tail technical docs the search engine skipped to save bandwidth

## Output organization

```
.research/
  q1-tavily.json, q1-exa.json, ...   # search results (one per engine per sub-query)
  notes.md                           # working notes / triangulation table
  synthesis.md                       # final deliverable
.firecrawl/
  *.md                               # Tier 2 scrapes
```

Both directories should be in `.gitignore`. The skill never deletes them — they're useful as a research audit trail.

## Anti-patterns

- **Single-query research** — produces single-source bias. Decompose first.
- **Single-engine research** — Tavily and Exa surface different sources; for anything important, query both.
- **Reading every result fully** — context bloat. Triage first, read top 3 fully.
- **Citing without dates** — strips the reader's ability to judge currency.
- **Using Tier 2 for breadth** — Firecrawl credits are precious. Use the Tier-1 search layer for breadth, Tier 2 only for specific known-hard pages.
- **Falling back to built-in WebSearch** — defeats the purpose of this skill. If the search APIs fail, use `WebFetch` on a specific known URL, not `WebSearch`.

## Setup

See `README.md` in this skill directory for one-time setup (API keys, dependencies,
and sourcing keys from a local secret vault).
