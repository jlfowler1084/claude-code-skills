# 3. Domain Modeling

*Read this when designing entities, value objects, domain exceptions, or domain events in a Python project.*

## Entities

Objects with identity that persists over time. Two entities with the same attributes but
different IDs are different objects.

```python
from dataclasses import dataclass, field
import uuid

@dataclass(slots=True)
class Task:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    title: str = ""
    status: str = "pending"

    def complete(self) -> None:
        """Business rule: only pending tasks can be completed."""
        if self.status != "pending":
            raise InvalidStateError(f"Cannot complete task in {self.status!r} state")
        self.status = "completed"

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Task):
            return NotImplemented
        return self.id == other.id

    def __hash__(self) -> int:
        return hash(self.id)
```

## Value Objects

Defined entirely by their attributes. Immutable. Two value objects with the same
attributes are the same thing.

```python
@dataclass(frozen=True, slots=True)
class Address:
    street: str
    city: str
    state: str
    zip_code: str

@dataclass(frozen=True, slots=True)
class DateRange:
    start: date
    end: date

    def __post_init__(self) -> None:
        if self.start > self.end:
            raise ValueError(f"Start {self.start} cannot be after end {self.end}")

    @property
    def days(self) -> int:
        return (self.end - self.start).days
```

## Domain Exceptions

Express business rules as exceptions. They belong in `domain/exceptions.py`.

```python
class DomainError(Exception):
    """Base for all domain errors."""

class InvalidStateError(DomainError):
    """Operation not allowed in current state."""

class InsufficientStockError(DomainError):
    def __init__(self, sku: str, available: int, requested: int) -> None:
        self.sku = sku
        self.available = available
        self.requested = requested
        super().__init__(
            f"Cannot allocate {requested} of {sku}: only {available} available"
        )
```

## Domain Events

Lightweight records of things that happened in the domain.

```python
from dataclasses import dataclass, field
from datetime import datetime, timezone

@dataclass(frozen=True, slots=True)
class DomainEvent:
    occurred_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

@dataclass(frozen=True, slots=True)
class OrderPlaced(DomainEvent):
    order_id: str = ""
    customer_id: str = ""
    total_cents: int = 0

@dataclass(frozen=True, slots=True)
class OrderShipped(DomainEvent):
    order_id: str = ""
    tracking_number: str = ""
```
