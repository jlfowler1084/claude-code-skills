---
name: python-core
description: >
  Modern Python 3.10+ coding standards and Pythonic patterns. Use this skill whenever writing,
  reviewing, or modifying ANY Python code -- including scripts, modules, functions, classes, CLI
  tools, data pipelines, tests, or async handlers. Triggers on .py files, Python code blocks,
  references to PEP 8, type hints, dataclasses, decorators, generators, context managers, error
  handling, logging, or any mention of Python best practices. Even if you think you know Python
  well, consult this skill -- it contains specific conventions and patterns that must be followed
  for code consistency across all projects.
allowed-tools:
  - Read
---

# Python Core Standards

Modern Python development patterns for Python 3.10+ based on PEP 8, Google Python Style Guide,
and established expert practices.

## Purpose

- Write consistent, readable, idiomatic Python
- Apply modern type hints correctly
- Choose the right data structures with performance awareness
- Handle errors, resources, and logging properly
- Use Pythonic patterns: protocols, generators, decorators, context managers
- Write maintainable async code

## When to Reference

Reference on every Python task. If you're writing or modifying a `.py` file, this skill applies.
For project-level structure and design patterns, also reference `python-architecture`.

---

## ⚠ Golden Rule: New Code vs Existing Code

**This skill defines the standard for NEW code.** It does not mandate refactoring existing,
working code. This distinction is critical for mature codebases.

| Situation | What to do |
|---|---|
| Writing a **new file or module** | Apply all standards in this skill fully |
| Writing a **new function** in an existing file | Apply standards to the new function; match the file's import style and conventions |
| **Modifying** an existing function (bug fix, feature) | Fix the bug / add the feature. Do NOT refactor the surrounding code to match this skill unless the ticket explicitly calls for it |
| **Dedicated refactoring ticket** | Apply skill standards to the scoped refactoring target only |

**Never do unsolicited refactoring.** If you're fixing a one-line bug in a 13,000-line file,
your diff should be one line — not 200 lines of os.path → pathlib conversions, type hint
additions, and exception narrowing that weren't asked for. Unsolicited changes create
regression risk and erode trust in the skill system.

**Match the file's conventions** when editing existing code. If the file uses `os.path`,
use `os.path` in your edit. If it uses `log()` callbacks instead of `logging`, use the
callback. Consistency within a file beats skill compliance.

> See [Recognized Legacy Patterns](references/recognized-legacy-patterns.md) for the catalogue of accepted legacy idioms in existing code.

---

## Reference Docs

| # | File | Read when… |
|---|------|-----------|
| 1 | [modern-type-hints.md](references/modern-type-hints.md) | Writing new functions or classes; reviewing type annotation usage; deciding whether to annotate existing functions |
| 2 | [data-structures.md](references/data-structures.md) | Choosing between dataclasses, Pydantic models, NamedTuples, or plain dicts |
| 3 | [pythonic-patterns.md](references/pythonic-patterns.md) | Implementing dunder methods, designing class interfaces, or choosing between class-based and callable patterns |
| 4 | [decorators.md](references/decorators.md) | Writing or reviewing function decorators, especially parameterized ones |
| 5 | [generators-itertools.md](references/generators-itertools.md) | Processing sequences, building data pipelines, or deciding between generators and lists |
| 6 | [context-managers.md](references/context-managers.md) | Managing resources or writing setup/teardown patterns |
| 7 | [error-handling.md](references/error-handling.md) | Writing exception hierarchies, scoping try blocks, or implementing fallback chains |
| 8 | [path-handling.md](references/path-handling.md) | File system operations; deciding between pathlib and os.path |
| 9 | [async-patterns.md](references/async-patterns.md) | Writing async functions, managing concurrency, or implementing async context managers |
| 10 | [logging.md](references/logging.md) | Adding logging to a new module; deciding between the logging module and print |
| 11 | [naming-conventions.md](references/naming-conventions.md) | Naming any Python identifier: modules, classes, functions, constants, or type variables |
| 12 | [docstrings.md](references/docstrings.md) | Writing docstrings for public functions, classes, or modules |
| — | [recognized-legacy-patterns.md](references/recognized-legacy-patterns.md) | Auditing existing code for compliance; deciding whether an established pattern is a violation |

---

## Key Principles

1. **Readability counts** -- Code is read 10x more than written. Optimize for the reader.
2. **Explicit is better than implicit** -- Clear intent beats cleverness.
3. **Errors should never pass silently** -- Handle or propagate; never swallow.
4. **Flat is better than nested** -- Use early returns to limit nesting to 3 levels max.
5. **Generators by default** -- Materialize to list only when you need `len()` or indexing.
6. **Accept broad, return narrow** -- Parameters use `Iterable`/`Mapping`; returns use `list`/`dict`.
7. **One obvious way** -- Don't offer multiple approaches when one is clearly better.
8. **Practicality beats purity** -- Standards serve the code, not the other way around.
9. **Match the file** -- When editing existing code, match the file's conventions over this skill.
10. **No drive-by refactoring** -- Fix what you were asked to fix. Nothing more.

## Related Skills

- `python-architecture` -- project structure, design patterns, and architectural decisions for Python applications
