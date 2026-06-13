# 4. Repository Pattern

*Read this when abstracting data access behind a Protocol interface, or when writing fake repositories for testing.*

Abstract storage behind a protocol. One repository per aggregate root.

```python
# domain/ or service_layer/ -- the interface
from typing import Protocol

class TaskRepository(Protocol):
    def get(self, task_id: str) -> Task | None: ...
    def add(self, task: Task) -> None: ...
    def list_by_status(self, status: str) -> list[Task]: ...

# adapters/repository.py -- concrete implementation
class SqlTaskRepository:
    def __init__(self, session) -> None:
        self._session = session

    def get(self, task_id: str) -> Task | None:
        row = self._session.execute(
            "SELECT * FROM tasks WHERE id = :id", {"id": task_id}
        ).fetchone()
        return self._to_entity(row) if row else None

    def add(self, task: Task) -> None:
        self._session.execute(
            "INSERT INTO tasks (id, title, status) VALUES (:id, :title, :status)",
            {"id": task.id, "title": task.title, "status": task.status},
        )

    def list_by_status(self, status: str) -> list[Task]:
        rows = self._session.execute(
            "SELECT * FROM tasks WHERE status = :status", {"status": status}
        ).fetchall()
        return [self._to_entity(r) for r in rows]

    @staticmethod
    def _to_entity(row) -> Task:
        return Task(id=row.id, title=row.title, status=row.status)

# Fake for testing -- trivial to build
class FakeTaskRepository:
    def __init__(self, tasks: list[Task] | None = None) -> None:
        self._tasks: dict[str, Task] = {t.id: t for t in (tasks or [])}

    def get(self, task_id: str) -> Task | None:
        return self._tasks.get(task_id)

    def add(self, task: Task) -> None:
        self._tasks[task.id] = task

    def list_by_status(self, status: str) -> list[Task]:
        return [t for t in self._tasks.values() if t.status == status]
```
