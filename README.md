# Claude Code Skills

A collection of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills for common development patterns. Each skill is a markdown file that teaches Claude Code domain-specific best practices, enforcing production-quality patterns across your AI-assisted development sessions.

## What Are Claude Code Skills?

Skills are markdown files that Claude Code reads on demand to learn domain-specific patterns and best practices. They load when relevant to the current task, extending Claude's capabilities without consuming the main instruction budget.

Think of them as specialized playbooks: instead of repeating "always use CmdletBinding" or "don't forget OutputType" on every prompt, you install the skill once and Claude Code follows the patterns automatically.

## Installation

### Global (all projects)

Copy the skill folder to your global Claude Code config:

```
~/.claude/skills/<skill-name>/SKILL.md
```

Example:

```bash
cp -r skills/powershell-windows ~/.claude/skills/powershell-windows
```

### Per-Project

Copy the skill folder into your project's `.claude` directory:

```
<project-root>/.claude/skills/<skill-name>/SKILL.md
```

Example:

```bash
cp -r skills/powershell-windows .claude/skills/powershell-windows
```

## Available Skills

| Skill | Description | Key Topics |
|-------|-------------|------------|
| [powershell-windows](skills/powershell-windows/) | Production PowerShell patterns for Windows | Advanced functions, OutputType, splatting, tab completion, structured logging, Task Scheduler, PSScriptAnalyzer, error handling, encoding |
| [web-research](skills/web-research/) | Multi-source web research with citation discipline | Tiered search (Tavily + Exa), Firecrawl scrape, WebFetch fallback, query decomposition, source triage, cross-source triangulation, dated citations |
| [python-core](skills/python-core/) | Modern Python 3.10+ standards and Pythonic patterns | Type hints, dataclasses, decorators, generators, context managers, error handling, async, logging, naming, docstrings |
| [python-architecture](skills/python-architecture/) | Python project structure and design patterns | src-layout, SOLID, domain modeling, repository pattern, service layer, dependency injection, configuration, testing patterns |
| [regression-check](skills/regression-check/) | Verify shipped features still exist via a feature manifest | feature-manifest.json, export/pattern checks, halt-on-regression, optional shell script |
| [post-deployment](skills/post-deployment/) | Post-deploy structural checks + interactive smoke test | file/canonical/git verification, functional smoke test, blocker-only reporting |
| [git-branching](skills/git-branching/) | Branch-vs-main decisions, naming, merge strategy, optional branch-and-PR policy | feature-branch criteria, naming convention, squash/regular merge, post-merge cleanup, worktree-policy enforcement, refusal protocol |
| [worktree-management](skills/worktree-management/) | Isolated git worktree workflow for branch work | .worktrees/ gitignore guard, project-local worktrees, dependency auto-install, clean-baseline tests, post-merge cleanup |
| [safe-commit](skills/safe-commit/) | Pre-commit verification gate | branch check, stray-commit detection, file-integrity, secret scan, optional local-model review, test run, push |
| [prompt-engineering](skills/prompt-engineering/) | Session-handoff prompt files and model-tier selection | @-file invocation, Haiku/Sonnet/Opus tiers, filename convention, prompt-file contents |
| [api-governance](skills/api-governance/) | Cost discipline for outbound AI/API calls + model-tier selection | pre-call cascade (MCP/REST/cache), Haiku/Sonnet/Opus tiers, THINK-vs-DO heuristic, model-tier declaration |
| [hunt](skills/hunt/) | Parallel hypothesis-driven bug investigation | decompose into hypotheses, parallel read-only agents, ranked synthesis, falsification test, optional worktree fix |
| [subagent-coordinator](skills/subagent-coordinator/) | Protocol for delegating multi-file work to subagents | PLAN/EXECUTE/VERIFY/REVIEW/COMMIT, structured contracts, clean-checkout smoke gate, coordinator-owned commits |

## Contributing

Contributions are welcome! If you have a skill that enforces production patterns for a specific domain, open a PR. Each skill should include:

- `SKILL.md` — The skill file with YAML frontmatter and pattern documentation
- `README.md` — Description, sources, validation results, and before/after examples

Skills should be opinionated and practical — teach Claude Code what experienced developers already know, so it produces production-ready code from the first generation.

## Author

**Joseph Fowler** — IT Infrastructure Professional, Indianapolis, IN

20 years of enterprise IT operations experience spanning Windows infrastructure, automation, and DevOps.

[GitHub Profile](https://github.com/jlfowler1084)

## License

[MIT](LICENSE)
