# Recognized Legacy Patterns

*Read this when auditing existing code for compliance, or deciding whether an established pattern in a file is a violation of python-core standards.*

The following patterns exist in mature codebases and are **not** violations of this
skill when found in existing code. Do not refactor them unless explicitly asked.

| Pattern | Where You'll See It | Why It Exists |
|---|---|---|
| `os.path` for all path ops | Files predating pathlib adoption | Works fine, migration is a separate task |
| `log()` callback parameter | Functions serving both CLI and GUI | Routes output flexibly without coupling to `logging` |
| `print()` in CLI tools | Interactive scripts, batch tools | Intentional user-facing output, not debug spew |
| `except Exception` in fallback chains | Pipeline/extraction code | Deliberate graceful degradation with logging |
| No type hints on parameters | Large legacy files | Retroactive annotation is high-effort/high-risk |
| Plain dicts as data containers | Entire codebases without dataclasses | Works fine; introduce dataclasses only in new modules |
| `HAS_MODULE` feature flags | `try: import X; HAS_X = True / except ImportError: HAS_X = False` | Optional dependency handling across environments |
| `sys.path.insert(0, ...)` | Scripts importing siblings | Flat project structures without installable packages |
| UTF-8 stdout reconfigure | `sys.stdout.reconfigure(encoding='utf-8')` at script top | Windows console encoding compatibility |
| `settings.json` config loading | Reading paths from a central JSON config file | Simple configuration without pydantic-settings |
