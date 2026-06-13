# 4. Decorators

*Read this when writing or reviewing function decorators, especially parameterized decorators or decorators that must preserve function metadata.*

```python
import functools
import time
import logging
from collections.abc import Callable
from typing import ParamSpec, TypeVar

P = ParamSpec("P")
R = TypeVar("R")

# Always use @functools.wraps to preserve function metadata
def log_calls(func: Callable[P, R]) -> Callable[P, R]:
    """Log function entry and exit with timing."""
    logger = logging.getLogger(func.__module__)

    @functools.wraps(func)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        logger.debug("Calling %s", func.__qualname__)
        start = time.perf_counter()
        try:
            result = func(*args, **kwargs)
            elapsed = time.perf_counter() - start
            logger.debug("%s completed in %.3fs", func.__qualname__, elapsed)
            return result
        except Exception:
            elapsed = time.perf_counter() - start
            logger.exception("%s failed after %.3fs", func.__qualname__, elapsed)
            raise
    return wrapper

# Parameterized decorator
def retry(max_attempts: int = 3, delay: float = 1.0) -> Callable[[Callable[P, R]], Callable[P, R]]:
    """Retry a function on exception."""
    def decorator(func: Callable[P, R]) -> Callable[P, R]:
        @functools.wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            last_exc: Exception | None = None
            for attempt in range(1, max_attempts + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as exc:
                    last_exc = exc
                    if attempt < max_attempts:
                        time.sleep(delay * attempt)
            raise last_exc  # type: ignore[misc]
        return wrapper
    return decorator
```
