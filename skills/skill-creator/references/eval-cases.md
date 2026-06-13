# Eval Cases for Skills

How to author, run, and record eval cases. Extracted from the original
`skill-creator` SKILL.md as part of the modular refactor.

Eval authoring is lower-frequency than skill authoring itself — most authoring
sessions don't reach this content — so it lives in `references/` rather than
inline in SKILL.md.

---

## When to Author Eval Cases

Default: yes for workflows with objectively verifiable outputs. Skip for skills
with subjective outputs (writing style, design aesthetics, judgment calls)
where pass/fail can't be assessed with evidence.

Number of evals: 3–5 realistic test prompts per skill. More than 5 typically
duplicates coverage; fewer than 3 leaves gaps.

---

## Eval Schema

Save eval definitions to `evals/evals.json` in the skill directory:

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "name": "descriptive-slug",
      "prompt": "What a real user would actually say",
      "context": "Setup: what state exists before the prompt runs",
      "expectations": [
        "Objectively verifiable outcome 1",
        "Objectively verifiable outcome 2"
      ],
      "files": ["evals/fixtures/sample-input.json"]
    }
  ]
}
```

### Field guidance

- **`prompt`** — Realistic, what a real user would type. Not abstract requests.
- **`context`** — Pre-existing state, NOT the expected behavior. The setup, not
  the verdict.
- **`expectations`** — Objectively verifiable. Each expectation is a single
  pass/fail claim with concrete evidence. Avoid "the skill should be helpful"
  (subjective) — prefer "the skill produces a file at `path/to/X.md`" or "the
  skill names the function `Resolve-DeployTokens`".
- **`files`** — Optional. Fixtures in `evals/fixtures/` that the prompt references.

---

## Eval Coverage Guidance

A good eval set includes a mix:

- **Happy path** — the obvious trigger, the expected outcome.
- **Edge cases** — unusual but valid inputs (empty arrays, single-element arrays,
  unicode, very long inputs).
- **Error conditions** — invalid inputs, missing prerequisites, conflicting
  signals.
- **Implicit triggers** — natural-language prompts that should fire the skill
  without literal keyword matching. These test the description's semantic
  surface.

If your skill has a clear failure mode (e.g., a known regression, a gotcha that
caused a past bug), include an eval that specifically guards against that
regression.

---

## Running Evals

Each eval runs as a manual Claude Code session:

1. Set up the context described in the eval case (create fixture files, set up
   git state, etc.).
2. Paste the prompt.
3. Observe whether each expectation is met. Capture concrete evidence (file
   paths, function names, output excerpts).
4. Record results to `evals/results/<YYYY-MM-DD>-<eval-name>.json`.

### Result schema

```json
{
  "eval_id": 1,
  "eval_name": "descriptive-slug",
  "run_date": "2026-04-01",
  "skill_commit": "abc1234",
  "pass_rate": 0.8,
  "results": [
    {
      "expectation": "The specific expectation text",
      "passed": true,
      "evidence": "Concrete proof from the session"
    }
  ],
  "notes": "Any observations about the run"
}
```

The `skill_commit` field correlates results back to the exact source state, so
you can A/B compare quality across changes via `git log evals/results/`.

---

## Quality Gate

**80% pass rate minimum** before shipping a skill or a skill change.

If below 80%:

1. Identify which expectations failed and why.
2. Decide whether the skill body, the description (triggering surface), or the
   eval itself is wrong. All three are valid failure causes.
3. Make targeted changes — do not rewrite everything at once.
4. Re-run all evals. Compare pass rate to the previous commit.
5. If improved, commit. If not, try a different change.

The eval results with `skill_commit` hashes give you a quality signal correlated
to specific changes via git history.

---

## When to Skip Evals

Skills that produce subjective outputs (where pass/fail isn't decidable with
concrete evidence) should not have evals. Examples from the existing skill
catalog:

- `technical-writing` — output quality is editorial judgment, not verifiable
- `compound-engineering:ce-frontend-design` — visual quality is subjective
- `worktree-management` — outcome is a git state that's better verified by
  manual inspection than by structured eval cases

For these, rely on:

- Manual usage in real sessions (the "does it actually help" test)
- User feedback signals
- Periodic re-reading of the SKILL.md body to catch staleness

If you're unsure whether your skill qualifies for evals, default to writing
them. The schema is small and the time cost is low; the worst case is you
discover the outputs are subjective and remove them.
