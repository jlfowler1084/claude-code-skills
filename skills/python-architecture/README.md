# Python Architecture Skill

A Claude Code skill for project structure, design patterns, and architectural decisions in maintainable Python applications. Complements [`python-core`](../python-core/) (line-level standards) with the layer above it: where code lives and how it's wired.

## What This Skill Does

A thin `SKILL.md` trigger plus on-demand `references/` covering layout, SOLID, domain modeling, and the Repository / Service Layer / Unit-of-Work patterns. Like `python-core`, it refuses unsolicited restructuring — patterns apply to greenfield work or an explicit refactoring ticket, never to a working module you're only bug-fixing.

## What's Inside

| Reference | Covers |
|-----------|--------|
| greenfield-vs-brownfield | whether to apply patterns to an existing codebase at all |
| project-layout | src-layout, `pyproject.toml`, package boundaries |
| solid-principles | SRP, OCP, LSP, ISP, DIP with Python examples |
| domain-modeling | entities, value objects, domain events, exceptions |
| repository-pattern | abstracting data access with Protocols and fakes |
| service-layer | use-case handlers and dependency injection |
| configuration | 12-factor config with pydantic-settings |
| testing-patterns | test pyramid, fakes vs mocks, parametrize, layout |

## Installation

```bash
# Global (all projects)
cp -r skills/python-architecture ~/.claude/skills/python-architecture

# Per-project
cp -r skills/python-architecture .claude/skills/python-architecture
```
