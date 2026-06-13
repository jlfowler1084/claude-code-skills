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
mkdir -p ~/.claude/skills/powershell-windows
cp skills/powershell-windows/SKILL.md ~/.claude/skills/powershell-windows/SKILL.md
```

### Per-Project

Copy the skill folder into your project's `.claude` directory:

```
<project-root>/.claude/skills/<skill-name>/SKILL.md
```

Example:

```bash
mkdir -p .claude/skills/powershell-windows
cp skills/powershell-windows/SKILL.md .claude/skills/powershell-windows/SKILL.md
```

## Available Skills

| Skill | Description | Key Topics |
|-------|-------------|------------|
| [powershell-windows](skills/powershell-windows/) | Production PowerShell patterns for Windows | Advanced functions, OutputType, splatting, tab completion, structured logging, Task Scheduler, PSScriptAnalyzer, error handling, encoding |
| [web-research](skills/web-research/) | Multi-source web research with citation discipline | Tiered search (Tavily + Exa), Firecrawl scrape, WebFetch fallback, query decomposition, source triage, cross-source triangulation, dated citations |

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
