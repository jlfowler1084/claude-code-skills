# 2. SOLID Principles in Python

*Read this when applying SOLID principles — SRP, OCP, LSP, ISP, or DIP — to Python code, with concrete before/after examples.*

## Single Responsibility Principle (SRP)

Each module, class, or function should have one reason to change.

```python
# BAD: One class doing parsing, validation, and persistence
class OrderProcessor:
    def parse_csv(self, path): ...
    def validate_order(self, data): ...
    def save_to_database(self, order): ...
    def send_confirmation(self, order): ...

# GOOD: Separate responsibilities
class OrderParser:
    def parse(self, path: Path) -> list[RawOrder]: ...

class OrderValidator:
    def validate(self, raw: RawOrder) -> Order: ...

class OrderRepository:
    def save(self, order: Order) -> None: ...

# Service layer orchestrates them
def process_orders(parser, validator, repo, path):
    for raw in parser.parse(path):
        order = validator.validate(raw)
        repo.save(order)
```

## Open-Closed Principle (OCP)

Open for extension, closed for modification. Use protocols and composition.

```python
from typing import Protocol

class Exporter(Protocol):
    def export(self, data: list[dict]) -> bytes: ...

class CsvExporter:
    def export(self, data: list[dict]) -> bytes: ...

class JsonExporter:
    def export(self, data: list[dict]) -> bytes: ...

# Adding a new format = new class, zero changes to existing code
class ParquetExporter:
    def export(self, data: list[dict]) -> bytes: ...

def generate_report(exporter: Exporter, data: list[dict]) -> bytes:
    return exporter.export(data)
```

## Liskov Substitution Principle (LSP)

Subtypes must be substitutable for their base types without breaking behavior.

```python
# BAD: Square violates Rectangle's behavioral contract
class Rectangle:
    def set_width(self, w): self.width = w
    def set_height(self, h): self.height = h

class Square(Rectangle):  # Breaks LSP -- setting width must also set height
    def set_width(self, w): self.width = self.height = w

# GOOD: Use composition or separate types
@dataclass(frozen=True, slots=True)
class Rectangle:
    width: float
    height: float

    @property
    def area(self) -> float:
        return self.width * self.height

@dataclass(frozen=True, slots=True)
class Square:
    side: float

    @property
    def area(self) -> float:
        return self.side ** 2
```

## Interface Segregation Principle (ISP)

Clients should not depend on methods they don't use. Use small, focused protocols.

```python
# BAD: Fat interface forces implementations to stub unused methods
class DataStore(Protocol):
    def read(self, key: str) -> bytes: ...
    def write(self, key: str, data: bytes) -> None: ...
    def delete(self, key: str) -> None: ...
    def list_keys(self) -> list[str]: ...
    def get_metadata(self, key: str) -> dict: ...

# GOOD: Split into focused protocols
class Readable(Protocol):
    def read(self, key: str) -> bytes: ...

class Writable(Protocol):
    def write(self, key: str, data: bytes) -> None: ...

# Compose when you need both
class ReadWriteStore(Readable, Writable, Protocol): ...
```

## Dependency Inversion Principle (DIP)

High-level modules define interfaces. Low-level modules implement them.

```python
# domain/model.py -- defines what it NEEDS, not how it's done
from typing import Protocol

class OrderRepository(Protocol):
    def get(self, order_id: str) -> Order | None: ...
    def save(self, order: Order) -> None: ...

# service_layer/handlers.py -- depends on the abstraction
def place_order(repo: OrderRepository, cmd: PlaceOrder) -> str:
    order = Order.create(cmd.customer_id, cmd.items)
    repo.save(order)
    return order.id

# adapters/repository.py -- implements the abstraction
class SqlOrderRepository:
    def __init__(self, session) -> None:
        self._session = session

    def get(self, order_id: str) -> Order | None: ...
    def save(self, order: Order) -> None: ...
```
