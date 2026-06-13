# 2. Data Structure Selection

*Read this when choosing between dataclasses, Pydantic models, NamedTuples, or plain dicts for a new data container.*

| Use Case | Choice | Why |
|---|---|---|
| Simple data container | `@dataclass` | Built-in, zero deps, `slots=True` for performance |
| Immutable data | `@dataclass(frozen=True, slots=True)` | Hashable, safe, memory-efficient |
| Validation + serialization (API boundaries) | `pydantic.BaseModel` | JSON schema, parsing, coercion |
| High-volume simple records | `NamedTuple` | Tuple performance, immutable, iterable |
| Config/settings from env | `pydantic-settings` | Type-safe env var parsing |
| Performance-critical with custom validators | `attrs` | Fastest, flexible validation |

**Transition guidance:** For new modules, prefer dataclasses. For modifications to
existing files that use plain dicts as data containers, match the file's convention
(keep using dicts). Only introduce dataclasses into an existing file when the change
naturally calls for a new data structure — don't convert working dicts to dataclasses
as part of an unrelated change.

```python
# Standard dataclass -- use for most domain objects in NEW code
from dataclasses import dataclass, field

@dataclass(slots=True, frozen=True)
class Config:
    host: str
    port: int = 8080
    tags: list[str] = field(default_factory=list)

# Mutable dataclass with __post_init__ validation
@dataclass(slots=True)
class Batch:
    reference: str
    quantity: int

    def __post_init__(self) -> None:
        if self.quantity <= 0:
            raise ValueError(f"Quantity must be positive, got {self.quantity}")

# Pydantic at API boundaries
from pydantic import BaseModel, Field

class CreateUserRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: str
    age: int = Field(ge=0, le=150)

# NamedTuple for lightweight records
from typing import NamedTuple

class Point(NamedTuple):
    x: float
    y: float
    label: str = ""
```
