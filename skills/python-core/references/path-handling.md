# 8. Path Handling

*Read this when writing file system operations, deciding between pathlib and os.path, or working with new vs existing path-handling code.*

**New code:** Use pathlib for all path operations.
**Existing code:** If a file uses `os.path`, continue using `os.path` in your edits.
Migrating os.path → pathlib is a separate, opt-in refactoring task — never do it
alongside feature work or bug fixes.

```python
from pathlib import Path

# Use Path for new code -- not os.path.join or string concatenation
config_path = Path("data") / "config" / "settings.json"

# Common operations
if config_path.exists():
    data = config_path.read_text(encoding="utf-8")

name = config_path.stem       # "settings"
ext = config_path.suffix      # ".json"
parent = config_path.parent   # Path("data/config")

# Glob patterns
for py_file in Path("src").rglob("*.py"):
    process(py_file)

# Create directories safely
output_dir = Path("output") / "reports"
output_dir.mkdir(parents=True, exist_ok=True)

# Resolve to absolute path
abs_path = config_path.resolve()
```
