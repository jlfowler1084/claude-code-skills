# 1. Project Layout

*Read this when scaffolding a new Python project, choosing a directory structure, or setting up pyproject.toml.*

Use the `src` layout with installable package for **new projects**. This prevents
accidental imports from the working directory and mirrors production installation.

```
project-name/
├── pyproject.toml              # Project metadata, deps, tool config
├── README.md
├── .env.example                # Document required env vars
├── Makefile                    # Common commands: test, lint, run
│
├── src/
│   └── project_name/
│       ├── __init__.py
│       ├── config.py           # Settings from environment
│       │
│       ├── domain/             # Business logic (no external deps)
│       │   ├── __init__.py
│       │   ├── model.py        # Entities, value objects, aggregates
│       │   ├── events.py       # Domain events (dataclasses)
│       │   └── exceptions.py   # Domain-specific exceptions
│       │
│       ├── service_layer/      # Use case orchestration
│       │   ├── __init__.py
│       │   ├── handlers.py     # Command/event handlers
│       │   └── unit_of_work.py # Transaction boundary
│       │
│       ├── adapters/           # External world interfaces
│       │   ├── __init__.py
│       │   ├── repository.py   # Data access implementations
│       │   ├── orm.py          # ORM mappings (if applicable)
│       │   └── notifications.py
│       │
│       └── entrypoints/        # How the outside world talks to us
│           ├── __init__.py
│           ├── api.py          # FastAPI/Flask routes
│           └── cli.py          # CLI commands
│
└── tests/
    ├── conftest.py             # Shared fixtures
    ├── unit/                   # Fast, no I/O, no DB
    │   ├── test_model.py
    │   └── test_handlers.py
    ├── integration/            # Touches DB, filesystem, network
    │   ├── test_repository.py
    │   └── test_orm.py
    └── e2e/                    # Full stack through entrypoints
        └── test_api.py
```

## Layout Rules

- **`domain/`** has ZERO imports from `adapters/`, `entrypoints/`, or external frameworks.
  It depends only on the Python standard library. This is the Dependency Rule.
- **`service_layer/`** depends on `domain/` and abstract interfaces (protocols). Never on
  concrete adapters.
- **`adapters/`** implements the interfaces that `service_layer/` defines.
- **`entrypoints/`** is thin -- translates HTTP/CLI into service layer calls.
- **`config.py`** reads from environment variables. No hardcoded values.

## For Existing Projects Without This Layout

If a project uses a flat structure (all .py files in one directory), **do not restructure
it** unless a dedicated migration ticket is open. Instead:

- Add new modules as separate files in the existing structure
- Follow the dependency direction principle (new code doesn't import from entrypoints)
- Use the project's existing import patterns (e.g., `sys.path.insert` for siblings)

## pyproject.toml Skeleton

```toml
[project]
name = "project-name"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = []

[project.optional-dependencies]
dev = ["pytest", "pytest-cov", "mypy", "ruff"]

[tool.pytest.ini_options]
testpaths = ["tests"]
markers = ["slow: marks tests as slow"]

[tool.mypy]
strict = true
warn_return_any = true

[tool.ruff]
target-version = "py310"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "B", "SIM", "TCH"]
```
