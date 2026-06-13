# web-research skill — setup

Tiered web research with a methodology layer: a two-engine search layer
(**Tavily** for keyword/recency, **Exa** for neural/semantic) escalating to
**Firecrawl** scrape and built-in **WebFetch**. See `SKILL.md` for what the skill
does and how it routes; this file covers one-time setup.

## Prerequisites

- Python 3.10+
- Node.js (for the Firecrawl CLI)
- Git Bash or PowerShell 7

## One-time setup

### 1. Install the Python SDKs

```bash
python -m pip install -r ~/.claude/skills/web-research/tools/requirements.txt
```

Installs `tavily-python` and `exa-py`. No other dependencies.

### 2. Get API keys

| Engine | Sign up | Free tier | Key format / env var |
|--------|---------|-----------|----------------------|
| Tavily | https://app.tavily.com | 1,000 requests/mo | `tvly-...` → `TAVILY_API_KEY` |
| Exa | https://dashboard.exa.ai | varies by plan — check dashboard | (opaque) → `EXA_API_KEY` |
| Firecrawl | https://firecrawl.dev | 500 pages/mo | `fc-...` → `firecrawl login` |

### 3. Provide the keys to the tools

The Python tools read `TAVILY_API_KEY` and `EXA_API_KEY` from the process
environment (with a Windows user-registry fallback). Firecrawl uses its own
`firecrawl login`. Pick whichever key-management approach fits your machine:

**Option A — Windows user environment (simplest):**

```powershell
setx TAVILY_API_KEY "tvly-your-key-here"
setx EXA_API_KEY     "your-exa-key-here"
# Firecrawl stores its key via:  firecrawl login
```

> `setx` writes to the user registry but does NOT propagate to already-running
> shells or editors. After running it, fully sign out of Windows (or reboot) and
> relaunch your terminal/editor from a fresh start — a pinned-icon process tree
> can resume with a stale environment. The wrapper tools include a registry
> fallback for exactly this gap, but a clean sign-in is the most robust fix.

**Option B — source from a local secret vault (recommended for shared/work machines):**

Keep the keys out of the registry entirely and inject them per session from your
vault of choice. Add a small bootstrap to your shell profile or a session-start
hook, and **replace `your-vault-cli` with your vault's actual fetch command**:

```powershell
# --- TUNE THIS to your local vault CLI ---
$env:TAVILY_API_KEY    = (your-vault-cli get tavily-api-key)
$env:EXA_API_KEY       = (your-vault-cli get exa-api-key)
$env:FIRECRAWL_API_KEY = (your-vault-cli get firecrawl-api-key)
```

The tools only need the values present in the environment at call time — they
don't care where they came from. This keeps secrets in your vault and off disk.

### 4. Verify

```bash
# Firecrawl
firecrawl --status

# Tavily (prints JSON; non-zero exit = setup problem)
python ~/.claude/skills/web-research/tools/tavily-search.py "hello world" --max-results 1 --no-raw

# Exa (prints JSON; non-zero exit = setup problem)
python ~/.claude/skills/web-research/tools/exa-search.py "hello world" --num-results 1 --no-text
```

## Usage

The skill is auto-invoked on research-shaped prompts. You can also invoke it
explicitly: "Use the web-research skill to investigate X." See `SKILL.md` →
"Research methodology" for the exact workflow.

## Cost notes

- Tavily `advanced` depth counts as 1 request regardless of `max_results`.
- Exa charges per search (and optionally per content fetch) — check your plan.
- Firecrawl `scrape` consumes 1 credit per page.
- Nothing costs anything if the skill is not invoked — no background polling.

## Troubleshooting

**"TAVILY_API_KEY / EXA_API_KEY not found"** — see step 3. On Windows, confirm the
user-scope value:

```powershell
[Environment]::GetEnvironmentVariable('TAVILY_API_KEY', 'User')
[Environment]::GetEnvironmentVariable('EXA_API_KEY', 'User')
```

If that returns your key but the tool still can't see it, your shell inherited a
stale environment — sign out and back in, or use the vault bootstrap (Option B).

**"API call failed"** — check the engine's dashboard for quota status. If a search
tier is exhausted, the skill falls through to the next tier automatically.

**Firecrawl credits exhausted** — the skill refuses Tier 2 and routes to Tier 3 (WebFetch).
