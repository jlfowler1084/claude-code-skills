# 1. Modern Type Hints (Python 3.10+)

*Read this when writing new Python functions or classes, reviewing type annotation usage, or deciding whether to annotate existing functions.*

**New functions:** Type hints are required on all parameters and return values.
**Existing functions:** Leave as-is unless a refactoring ticket targets them. Adding type
hints to a 148-function file is a separate, planned effort — not drive-by work.

```python
# Use built-in generics -- never typing.List, typing.Dict, typing.Tuple
def process(items: list[str], config: dict[str, int]) -> bool: ...

# Use union syntax with | -- never typing.Union or typing.Optional
def fetch(url: str) -> dict | None: ...
def convert(value: str | int) -> float: ...

# Use collections.abc for abstract types in PARAMETERS (accept broad, return narrow)
from collections.abc import Mapping, Sequence, Iterable, Callable

def transform(data: Mapping[str, int]) -> list[str]: ...
def apply_all(funcs: Iterable[Callable[[int], int]], value: int) -> list[int]: ...

# TypeAlias for complex types (type statement requires 3.12+)
type JsonValue = str | int | float | bool | None | list["JsonValue"] | dict[str, "JsonValue"]
# On 3.10–3.11, use: JsonValue: TypeAlias = str | int | float | ...

# Use Protocol for structural typing (duck typing with type safety)
from typing import Protocol, runtime_checkable

@runtime_checkable
class Readable(Protocol):
    def read(self, n: int = -1) -> str: ...

# Self type for fluent interfaces (Python 3.11+)
from typing import Self

class Builder:
    def with_name(self, name: str) -> Self:
        self.name = name
        return self
```

**Anti-patterns to avoid (in new code):**
```python
# BAD: Legacy typing imports
from typing import List, Dict, Optional, Union, Tuple
# BAD: Optional instead of | None
def fetch(url: str) -> Optional[dict]: ...
# BAD: Any as a crutch -- use Protocol or concrete types
def process(data: Any) -> Any: ...
```
