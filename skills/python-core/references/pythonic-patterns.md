# 3. Pythonic Patterns

*Read this when implementing dunder methods, designing class interfaces, or choosing between class-based and callable-based patterns.*

## The Data Model (dunder methods)

Implement dunder methods to make objects work with Python's built-in operations.
Only implement what you need -- don't add dunders speculatively.

```python
@dataclass(slots=True)
class Money:
    amount: int  # cents
    currency: str = "USD"

    def __repr__(self) -> str:
        """Unambiguous representation for debugging."""
        return f"Money(amount={self.amount}, currency={self.currency!r})"

    def __str__(self) -> str:
        """Human-readable display."""
        return f"${self.amount / 100:.2f} {self.currency}"

    def __add__(self, other: "Money") -> "Money":
        if self.currency != other.currency:
            raise ValueError(f"Cannot add {self.currency} and {other.currency}")
        return Money(self.amount + other.amount, self.currency)

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Money):
            return NotImplemented
        return self.amount == other.amount and self.currency == other.currency

    def __hash__(self) -> int:
        return hash((self.amount, self.currency))

    def __bool__(self) -> bool:
        return self.amount != 0
```

## Protocols Over Inheritance

Prefer `Protocol` for defining interfaces. Use ABC only when you need shared implementation.

```python
from typing import Protocol

class Repository(Protocol):
    """Any object with these methods satisfies this interface."""
    def get(self, id: str) -> dict | None: ...
    def save(self, entity: dict) -> None: ...

# This class satisfies Repository without inheriting anything
class InMemoryRepo:
    def __init__(self) -> None:
        self._store: dict[str, dict] = {}

    def get(self, id: str) -> dict | None:
        return self._store.get(id)

    def save(self, entity: dict) -> None:
        self._store[entity["id"]] = entity
```

## First-Class Functions Replace Simple Patterns

Use callables instead of single-method classes for Strategy, Command, and similar patterns.

```python
# GOOD: Strategy as a callable
from collections.abc import Callable

type PricingStrategy = Callable[[float, int], float]  # 3.12+; use TypeAlias on 3.10–3.11

def bulk_pricing(unit_price: float, quantity: int) -> float:
    return unit_price * quantity * (0.9 if quantity > 100 else 1.0)

def premium_pricing(unit_price: float, quantity: int) -> float:
    return unit_price * quantity * 1.2

def calculate_total(strategy: PricingStrategy, unit_price: float, qty: int) -> float:
    return strategy(unit_price, qty)

# BAD: Single-method class just to hold a function
class BulkPricingStrategy:
    def calculate(self, unit_price, quantity):
        return unit_price * quantity * 0.9
```
