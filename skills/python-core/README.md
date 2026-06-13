# Python Core Standards Skill

A Claude Code skill that enforces modern, idiomatic Python 3.10+ across all AI-assisted code generation. When installed, Claude applies consistent type hints, error handling, logging, and Pythonic patterns instead of producing generic, lowest-common-denominator Python.

## What This Skill Does

The `SKILL.md` is a thin trigger; the substance lives in `references/`, loaded on demand by topic so it costs almost nothing until a Python task is in play. It also encodes a **golden rule** — apply standards to *new* code, never refactor working existing code unsolicited — which keeps diffs small and trustworthy in mature codebases.

## What's Inside

| Reference | Covers |
|-----------|--------|
| modern-type-hints | Optional unions, generics, `Protocol`, when to annotate |
| data-structures | dataclasses vs Pydantic vs NamedTuple vs dict |
| pythonic-patterns | dunder methods, class vs callable design |
| decorators | function decorators, parameterized decorators |
| generators-itertools | lazy pipelines, generators vs lists |
| context-managers | resource management, setup/teardown |
| error-handling | exception hierarchies, try-block scope, fallback chains |
| path-handling | pathlib vs os.path |
| async-patterns | async functions, concurrency, async context managers |
| logging | the logging module over print |
| naming-conventions | modules, classes, functions, constants, type vars |
| docstrings | public function/class/module docstrings |
| recognized-legacy-patterns | accepted legacy idioms — do NOT "fix" these |

## Installation

```bash
# Global (all projects)
cp -r skills/python-core ~/.claude/skills/python-core

# Per-project
cp -r skills/python-core .claude/skills/python-core
```

Pairs with the [`python-architecture`](../python-architecture/) skill for project-level structure and design patterns.
