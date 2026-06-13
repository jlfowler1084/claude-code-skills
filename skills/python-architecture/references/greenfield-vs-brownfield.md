# ⚠ Greenfield vs Brownfield

*Read this when deciding whether to apply `python-architecture` patterns to an existing codebase.*

This skill's patterns are **fully applicable to new projects and new modules.**
For existing, working codebases, apply them **only when a ticket explicitly calls for it.**

## Greenfield (new project / new module)

Apply all patterns: src/ layout, layered directories, domain modeling, repository
abstractions, full test pyramid. You're building from scratch — do it right.

## Brownfield (existing working codebase)

**Do NOT suggest architectural refactoring during unrelated work.** A 13,000-line
monolith with 148 functions is not a problem to solve during a bug fix. It's a
working system that pays the bills.

| Situation | What to do |
|---|---|
| Bug fix in existing module | Fix the bug. Don't restructure the module. |
| New feature in existing project | Apply patterns to the NEW code (new files, new modules). Wire it into the existing structure as-is. |
| Refactoring ticket open | Apply patterns to the scoped target. Don't let scope creep beyond the ticket. |
| No refactoring ticket | Don't suggest splitting files, adding layers, or converting to repository pattern. Just do the task. |

**The "don't recommend rewriting working components" rule in project CLAUDE.md files takes
precedence over this skill's architectural recommendations.** When in doubt, do less.
