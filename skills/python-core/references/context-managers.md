# 6. Context Managers

*Read this when managing resources, implementing setup/teardown patterns, or writing code that needs guaranteed cleanup.*

```python
from contextlib import contextmanager
from pathlib import Path
import time
import logging

logger = logging.getLogger(__name__)

# Use contextlib for simple context managers
@contextmanager
def timed_operation(name: str):
    """Log elapsed time for an operation."""
    start = time.perf_counter()
    try:
        yield
    finally:
        elapsed = time.perf_counter() - start
        logger.info("%s completed in %.3fs", name, elapsed)

# Class-based for complex state management
class DatabaseTransaction:
    def __init__(self, connection):
        self.connection = connection
        self.cursor = None

    def __enter__(self):
        self.cursor = self.connection.cursor()
        return self.cursor

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is None:
            self.connection.commit()
        else:
            self.connection.rollback()
        self.cursor.close()
        return False  # Don't suppress exceptions

# File operations: prefer Path methods for simple reads/writes
content = Path("data.txt").read_text(encoding="utf-8")
Path("output.txt").write_text(result, encoding="utf-8")

# Use open() with context manager for streaming or line-by-line
with open(path, "r", encoding="utf-8") as f:
    for line in f:
        process(line)
```
