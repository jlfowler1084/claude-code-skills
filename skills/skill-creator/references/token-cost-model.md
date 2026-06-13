# Token Cost Model for Skills

Why progressive disclosure matters. The cost framing that motivates the
extraction heuristics in [modular-decomposition.md](modular-decomposition.md)
and the SKILL.md shape in [thin-skill-template.md](thin-skill-template.md).

This doc exists because rules about line counts are easy to game (Goodhart's Law:
`python-architecture` came in at exactly 500 lines, authored to the limit). The
real authoring constraint is *cost*. Once you understand where each piece of a
skill loads and what it costs in every session, the line-count rules stop feeling
arbitrary and start feeling cheap.

---

## The Three Loading Tiers

Claude Code's skill system loads skill content in three discrete tiers. Each tier
has a different trigger condition and a different cost. Authoring decisions are
fundamentally about **moving content to the lowest tier that still serves the
skill's purpose**.

### Tier 1: Metadata — *always* loaded

- **Loaded:** every Claude Code session, before any user prompt.
- **Content:** the YAML frontmatter `name` + `description` of every installed
  skill.
- **Cost:** ~50–100 tokens per skill. With 19 user-level skills, this is roughly
  1,500–2,000 tokens spent before any work begins.
- **Purpose:** semantic-matching surface for skill triggering.

### Tier 2: SKILL.md body — loaded *when the skill triggers*

- **Loaded:** only on sessions where Claude decides this skill is relevant to the
  current user prompt.
- **Content:** everything in SKILL.md *after* the closing `---` of frontmatter.
- **Cost:** scales linearly with body length. A 500-line body is ~2,500 tokens.
  A 100-line body is ~500.
- **Purpose:** the skill's working surface — what Claude reads to know how to do
  the work.

### Tier 3: `references/` and `scripts/` — loaded *on demand*

- **Loaded:** only when a specific subtask requires a specific reference (Claude
  fetches it via Read after triggering).
- **Content:** anything outside SKILL.md inside the skill directory.
- **Cost:** zero per-session unless actually consulted. When consulted, the cost
  is just that one file's size.
- **Purpose:** detailed implementation guidance, code samples, runbooks.

The cost asymmetry is the entire point. Tier 1 cost is paid in **every session**;
Tier 2 in **every triggering session**; Tier 3 only when **actually needed**.

---

## What "Triggering Session" Means in Practice

The four heavy skills before the modular refactors had triggers so broad that "every Python
edit", "every PowerShell edit", and "every Supabase import" all qualified.
Concretely:

- `python-core` (pre-refactor: 549 lines) fired on **every `.py` edit**. A
  routine bug-fix session that touched 3 Python files paid the full
  ~2,700-token Tier 2 cost three times in concentrated context turns, even when
  the skill content was only marginally relevant.
- `powershell-windows` (pre-refactor: 849 lines) fired on **every `.ps1` edit**.
  Same arithmetic, larger surface (~4,200 tokens).
- `nextjs-supabase` (pre-refactor: 935 lines) fired on **any Supabase import or
  middleware edit**. ~4,700 tokens per trigger.
- `python-architecture` (pre-refactor: 500 lines) fired on architectural
  questions in Python contexts. ~2,500 tokens per trigger.

If a session edited a Supabase route handler in TypeScript and a config script
in PowerShell in the same turn, the combined skill body cost was on the order of
9,000+ tokens — entirely independent of the user prompt's actual content.

After the modular refactors the same sessions pay **~300–500 tokens** of Tier 2 per skill
(60–97 lines), because the bulk of content moved to Tier 3 where the cost only
applies if a specific subtask actually consults a specific reference.

---

## The Authoring Implication

**Every authoring decision is an implicit Tier choice.**

When you write content in SKILL.md body, you are paying Tier 2 cost in every
triggering session forever. That cost compounds over hundreds of sessions per
month. If the content is detailed implementation guidance that only ~10% of
triggering sessions actually need, you are paying ~10x the necessary cost.

When you write the same content in `references/<topic>.md`, you pay Tier 3 cost
only on the sessions where Claude actually consults that reference. The other
90% of triggering sessions never see it.

This is *why* the decomposition heuristics in
[modular-decomposition.md](modular-decomposition.md) are framed around "scan vs
read":

- **Scannable content** (quick-ref tables, diagnostic checklists, principle
  lists) is high-frequency lookup. Inline it — paying Tier 2 cost is correct
  because nearly every triggering session will use it.
- **Narrative content** (how-to guides, deep explanations, code walkthroughs) is
  low-frequency lookup. Extract it — paying Tier 3 cost only on the few sessions
  that actually need it is the dramatic majority of the savings.

---

## Counter-intuitive Implication 1: Description bloat is expensive

The `description` field is Tier 1 — it loads in **every** session whether the
skill triggers or not. A 300-character description across 19 skills is ~5,700
characters of metadata loaded before any user prompt is processed.

This is why the compliance checker bounds descriptions at 50–300 characters and
why the [thin-skill-template.md](thin-skill-template.md) advises optimizing
ruthlessly. A description that drifts from 200 to 400 characters because the
author wanted to be "thorough" is paying a real cost in every session, including
sessions where the skill never fires.

---

## Counter-intuitive Implication 2: One large reference is cheaper than many small SKILL.md sections

A 400-line SKILL.md with ten 40-line sections costs Tier 2 = 400 lines on every
trigger.

A 100-line SKILL.md pointing at ten 40-line `references/` files costs Tier 2 = 100
lines on every trigger, plus Tier 3 = 40 lines on the (probably 1–2) sessions
that consult a specific reference.

The break-even is brutal. As long as fewer than ~7 of the 10 references are
consulted per triggering session on average, extraction wins. Real consultation
rates are usually 1–3, so extraction wins by a factor of 3–10x.

---

## Counter-intuitive Implication 3: A skill that never triggers is free at Tier 2 — but not at Tier 1

Adding a skill that never triggers in your normal workflow seems free. It isn't.

Tier 1 (metadata) loads regardless. A skill with a 200-character description
that fires once a month adds ~200 tokens of metadata to **every** session in
between, just to be available for that one fire. With 19 skills installed, the
cumulative Tier 1 cost is ~3,000–5,000 tokens of pure overhead.

This is why the compliance checker enforces a minimum description size (skills
without enough triggering text under-trigger and become wasted Tier 1) but also
implicitly discourages bloated descriptions (over-triggering wastes Tier 2 *and*
Tier 1 metadata). The optimum is descriptions that are precisely as long as
needed to anchor semantic matching — and no longer.

---

## How This Connects to the Plan

The refactor plan's compliance threshold tiers (ERROR >300, WARNING >150,
INFO >100) are calibrated against this cost model:

- **ERROR at >300 lines** ≈ ~1,500-token Tier 2 load. At this size, the skill is
  paying a per-trigger cost large enough to dominate the session budget for
  routine work. Almost certainly contains content that should be Tier 3.
- **WARNING at >150 lines** ≈ ~750-token Tier 2 load. Worth examining whether
  any content should be extracted, but not necessarily wrong.
- **INFO at >100 lines** ≈ ~500-token Tier 2 load. Healthy size for an
  index-style thin trigger. Below this is also fine for genuinely tiny skills.

A skill author who internalizes this cost model rarely needs to reach for the
threshold rules — the right answer becomes obvious from cost reasoning alone.
The thresholds exist as a Goodhart-resistant backstop for cases where someone
optimizes against the rule rather than the cost.

---

## Cross-References

- See [modular-decomposition.md](modular-decomposition.md) for the heuristics
  that translate this cost model into authoring decisions.
- See [thin-skill-template.md](thin-skill-template.md) for the SKILL.md shape
  that minimizes Tier 2 cost while keeping Tier 1 (description) sharp.
