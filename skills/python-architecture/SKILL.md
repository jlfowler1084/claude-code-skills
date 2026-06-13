---
name: python-architecture
description: >
  Python project structure, design patterns, and architectural decisions for building maintainable
  applications. Use this skill whenever scaffolding a new Python project, designing module
  boundaries, creating new feature layers, refactoring existing code, setting up tests, or making
  decisions about project layout, dependency injection, repositories, services, domain modeling, or
  config management. Also triggers on questions about SOLID principles in Python, Clean Architecture,
  hexagonal architecture, DDD, the repository pattern, service layers, or test organization.
  Whenever you are creating a new Python package, restructuring an existing one, or adding
  architectural layers -- consult this skill first.
allowed-tools:
  - Read
---

# Python Architecture Patterns

Project structure, design patterns, and architectural decisions for maintainable Python
applications. Complements the `python-core` skill which covers line-level coding standards.

## When to Use

- Establish consistent project layouts
- Apply SOLID principles idiomatically in Python
- Use proven architectural patterns (Repository, Service Layer, Unit of Work)
- Model domains with entities, value objects, and aggregates
- Organize tests effectively
- Manage configuration and dependencies cleanly

## When Not to Use

- Existing working codebase with no refactoring ticket open -- apply patterns only when a ticket explicitly calls for it
- Bug fix in an existing module -- fix the bug, don't restructure the module
- Line-level Python standards (type hints, decorators, generators, etc.) -- use `python-core` instead

---

## Reference Docs

| # | File | Read when… |
|---|------|-----------|
| 1 | [greenfield-vs-brownfield.md](references/greenfield-vs-brownfield.md) | Deciding whether to apply patterns to an existing codebase |
| 2 | [project-layout.md](references/project-layout.md) | Scaffolding a new project, src-layout, or pyproject.toml |
| 3 | [solid-principles.md](references/solid-principles.md) | Applying SRP, OCP, LSP, ISP, or DIP with Python examples |
| 4 | [domain-modeling.md](references/domain-modeling.md) | Designing entities, value objects, exceptions, or domain events |
| 5 | [repository-pattern.md](references/repository-pattern.md) | Abstracting data access; writing Protocol repos and fakes |
| 6 | [service-layer.md](references/service-layer.md) | Writing use case handlers or wiring dependency injection |
| 7 | [configuration.md](references/configuration.md) | 12-factor config with pydantic-settings |
| 8 | [testing-patterns.md](references/testing-patterns.md) | Test pyramid, fakes vs mocks, parametrize, file layout |

---

## 8. Performance-Aware Design

These are rules of thumb to build in from the start, not premature optimization.

- **Use `__slots__`** on dataclasses that will be instantiated thousands of times:
  `@dataclass(slots=True)` saves ~40% memory per instance.
- **Use `frozen=True`** on value objects -- makes them hashable and communicates intent.
- **Generator pipelines for file processing** -- never `readlines()` a file into a list
  when you can iterate line by line.
- **Profile before optimizing** -- use `cProfile` for CPU, `memory_profiler` for RAM,
  `Scalene` for both. Never guess.
- **Appropriate data structures**: `set` for membership tests, `dict` for lookups,
  `deque` for queues, `list` only when you need ordering + indexing.
- **Lazy loading** -- don't load data at import time. Load when first needed.
- **Batch database operations** -- one query for N items beats N queries for 1 item.

## 9. Architecture Decision Checklist

When designing a new module or feature, ask:

1. **Is this new code or existing code?** If existing, stop here — just do the task.
2. **Where does this live?** domain / service_layer / adapters / entrypoints?
3. **What does it depend on?** Dependencies should point inward (toward domain).
4. **How is it tested?** If it's hard to test, the design is wrong.
5. **What changes when requirements change?** SRP -- each component has one reason to change.
6. **Could I swap the adapter?** If switching from PostgreSQL to MongoDB requires changing
   domain code, the abstraction boundary is wrong.
7. **Is there a refactoring ticket?** If not, don't suggest architectural changes to working code.

## Related Skills

- `python-core` -- line-level Python standards (type hints, decorators, generators, etc.)
