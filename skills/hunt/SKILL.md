---
name: hunt
description: >
  Parallel hypothesis-driven bug investigation. Use when the user invokes /hunt,
  says "debug this", "why is this failing", pastes a stack trace or failing test output, or references a
  failing test that previous fixes did not resolve. Decomposes the bug into independent
  hypotheses, dispatches parallel read-only qa-agent subagents to investigate each one,
  then synthesizes findings into a ranked root-cause assessment with an optional
  implementer phase to apply the fix in a worktree. Never use implementer agents during
  investigation — hypothesis agents are always read-only qa-agents.
---

# /hunt - Parallel Bug Investigation

Fan-out bug investigation: decompose into hypotheses, investigate in parallel, synthesize into a ranked root-cause assessment, then optionally fix.

## When to use

**Triggers:** user invokes `/hunt`, says "debug this", "why is this failing", "what's broken", pastes a stack trace or error log, or references a failing test after previous fixes did not resolve the problem.

**Do NOT use when:**
- The root cause is already known — go straight to `safe-commit` + implementation.
- The bug is in a single function with an obvious typo or logic error.
- The user asks for a code review without a specific broken behavior to investigate.

---

## Phase 1 — Decompose

Given the bug description (error message, stack trace, failing test output, or behavior description), identify **4–8 independent investigation hypotheses**. Select only the hypotheses that are plausible for the specific bug — do not mechanically assign all 8.

**Hypothesis count guidance:**
- Single-file/isolated bug: 3–4 hypotheses
- Cross-module/system bug: 5–6 hypotheses
- Unknown/mysterious failure: use all 8

Available hypothesis types:

| Hypothesis | What to investigate |
|---|---|
| **Regression** | What recent commit touched this area? Does `git log --oneline -10 -- <path>` reveal a suspect change? |
| **Code pattern** | Are there other callsites that share the same root cause? Search for the function, class, or pattern involved using `Select-String` (PowerShell) or `rg` (ripgrep, cross-platform) — not `grep`. |
| **Fixture reproduction** | Can we isolate a minimal repro case from the failing test fixture? Is the test setup itself flawed? |
| **Dependency audit** | Did a package version change recently? Check `requirements.txt`, `package.json`, `pyproject.toml`, or `*.psd1` lock files for recent diffs. |
| **Issue tracker history** | Have similar bugs been filed before? If your project uses an issue tracker (Jira, GitHub Issues, etc.), search it for the keyword. If the tracker is unavailable, report "tracker unavailable — hypothesis skipped" rather than failing. |
| **Recent commits** | What changed in the last 5 commits touching this area? `git log --oneline -5 -- <affected-path>`. |
| **Environment** | Is this a Windows/PowerShell path issue, Python/Node version mismatch, or UTF-8 encoding problem? |
| **Log/stderr pattern** | What do the actual error logs say? Check stderr output, test runner verbose output, or structured log files. |

**Decompose output format** (coordinator produces this before dispatch):

```
Hypotheses for: <bug summary>
1. [Regression]   — Investigate recent commits to <path>
2. [Code pattern] — Search for <pattern> across <scope> (use Select-String or rg)
3. [Environment]  — Check PowerShell version and path encoding in <script>
4. [Log pattern]  — Read <log-file> for error context
```

---

## Phase 2 — Dispatch (parallel)

Dispatch each hypothesis as an **independent qa-agent subagent**. All agents run simultaneously — do NOT wait for one to finish before starting the next.

### Agent prompt template

Each qa-agent receives a prompt in this exact structure:

```
TASK: Investigate hypothesis: <hypothesis type> — <one-line description>

BUG DESCRIPTION:
<full original bug description, stack trace, or failing test output>

HYPOTHESIS TO INVESTIGATE:
<the single hypothesis this agent is responsible for>

FILES/AREAS TO INSPECT:
<specific files, directories, or search patterns — be explicit>

SEARCH TOOL GUIDANCE:
  - Use `Select-String` (PowerShell) or `rg` (ripgrep, cross-platform) — NOT `grep`
  - File content search: `Select-String -Path <file> -Pattern <pattern>` or `rg <pattern> <path>`
  - Git log search: `git log --oneline --all | Select-String <pattern>`

OUTPUT FORMAT (required):
Return a structured finding with these fields:
  evidence:       What you found (or explicitly "no evidence found")
  confidence:     high | medium | low
  proposed_fix:   Specific change that would resolve the bug, or "none" if evidence is insufficient

CONSTRAINTS:
  - Read-only: do NOT modify any files
  - Investigate exactly this one hypothesis — do not expand scope
  - If a specified file path does not exist or is inaccessible, report "path not found — hypothesis inconclusive" and stop. Do NOT broaden scope by searching parent directories.
  - Works with Windows PowerShell paths (backslash separators) and pytest/Pester test infrastructure
```

### Dispatch rules

- **Agent type:** always `qa-agent` (read-only) — never `implementer` during investigation.
- **One hypothesis per agent** — never bundle two hypotheses into one agent prompt.
- **All agents dispatch simultaneously** — fan-out is the point; sequential dispatch defeats it.
- **Coordinator does not read intermediate results** until all agents have returned.
- **Agent error recovery:** If an agent fails to complete or times out, re-dispatch that single hypothesis agent once. If it fails again, include it in the synthesis digest as "agent failed — no evidence" with low confidence. Do not block the overall synthesis on a single failed agent.

Reference `subagent-coordinator` skill for agent management patterns (Phase 2: EXECUTE).

---

## Phase 3 — Synthesize

After all hypothesis agents complete, run a synthesis pass. This is the coordinator's own reasoning step — not another subagent.

### Synthesis procedure

1. **Collect all agent findings** — list each agent's `evidence`, `confidence`, and `proposed_fix`.
2. **Rank by confidence and evidence quality:**

   Confidence level definitions:
   - **High**: 2+ agents converged on the same root cause, OR 1 agent found specific evidence at a named file:line
   - **Medium**: 1 agent found circumstantial evidence (timing, pattern match, plausible path)
   - **Low**: agents ruled out common causes but found no positive signal

   Ranking tiers:
   - HIGH confidence with specific file + line → top tier
   - MEDIUM confidence with circumstantial evidence → middle tier
   - LOW confidence or "no evidence found" → discard unless it rules out a common assumption
3. **Identify convergence:** if two or more agents point to the same root cause from different angles, that convergence raises the overall confidence.
4. **Pick the most likely root cause** and articulate the reasoning chain.
5. **Generate a falsification test:** a specific, verifiable assertion that would confirm or deny the root cause before any fix is applied.

---

## Output format

The coordinator produces this structured digest after Phase 3:

```
## /hunt: <bug summary>

### Hypotheses investigated (<N> agents)
- [HIGH]   <hypothesis type>: <evidence summary> → proposed fix: <fix>
- [MEDIUM] <hypothesis type>: <evidence summary> → proposed fix: <fix>
- [LOW]    <hypothesis type>: <evidence summary> → insufficient evidence

### Root cause hypothesis
<synthesizer's pick with reasoning>

### Falsification test
If this is the cause, then <X> should be true. Verify with: <specific command or assertion>

### Next step
Review the digest above, then select one action:
[ ] Auto-implement fix in worktree   [ ] Manual review needed
```

---

## Phase 4 — Implement (optional)

After presenting the Phase 3 digest, ask the user:

> "Synthesis confidence is [high/medium]. Shall I dispatch an implementer subagent to apply the fix in a worktree and run the full test suite?"

Only proceed if the user confirms.

### Implementer dispatch

When the user approves, delegate to an **implementer** subagent using the `subagent-coordinator` protocol (Phase 2: EXECUTE). The implementer contract must include:

```
TASK: Apply fix for <bug summary>
SCOPE: <specific files from root cause hypothesis>
ACCEPTANCE CRITERIA:
  1. The fix matches the proposed_fix from hypothesis [HIGH]: <hypothesis>
  2. The full test suite passes (pytest or Pester, as applicable)
  3. No files outside SCOPE are modified
CONSTRAINTS:
  - Use Edit (not Write) for all existing files
  - Run the full test suite before reporting done
  - If tests fail after the fix, report FAILED — do not attempt a second fix
BRANCH: <current worktree branch>
```

After the implementer returns:
- If STATUS is DONE and tests pass → proceed to `safe-commit` skill.
- If STATUS is FAILED → surface the failure to the user; do not retry automatically.
- If STATUS is BLOCKED → report which out-of-scope files need changes; escalate to user.

---

## Design constraints

- Hypothesis agents are always **qa-agent** (read-only) — never implementer.
- Each agent investigates **exactly one** hypothesis.
- The synthesizer is a **coordinator reasoning step** — not another subagent.
- Agents operate on **Windows PowerShell paths** (backslash, drive-letter prefix).
- Test infrastructure is **pytest** (Python projects) or **Pester** (PowerShell projects).
- All agent management follows the `subagent-coordinator` skill patterns.
- Falsification test is **mandatory** — synthesis without it is incomplete.

---

## Anti-patterns

- **Sequential dispatch** — investigating one hypothesis at a time defeats the fan-out. Dispatch all agents before reading any results.
- **Implementer during investigation** — hypothesis agents must be read-only. Using an implementer risks contaminating the working tree before the root cause is confirmed.
- **Bundling hypotheses** — one agent per hypothesis. Bundled agents produce muddled evidence that is hard to rank.
- **Skipping the falsification test** — proposing a fix without a verifiable assertion means the fix could be wrong and you won't know until it regresses.
- **Auto-implementing without user confirmation** — Phase 4 is opt-in. Always ask before dispatching the implementer.
