# 5. Service Layer

*Read this when writing use case handler functions or wiring dependency injection at application startup.*

Thin orchestration layer. Each function = one use case. Depends on abstractions.

```python
# service_layer/handlers.py
from domain.model import Task
from domain.exceptions import NotFoundError

def create_task(repo: TaskRepository, title: str) -> str:
    """Create a new task. Returns the task ID."""
    task = Task(title=title)
    repo.add(task)
    return task.id

def complete_task(repo: TaskRepository, task_id: str) -> None:
    """Mark a task as completed."""
    task = repo.get(task_id)
    if task is None:
        raise NotFoundError("Task", task_id)
    task.complete()  # Business rule enforcement happens in the domain
```

## Dependency Injection

For a solo developer, constructor injection or `functools.partial` is sufficient.
No DI framework needed.

```python
import functools

# Wire up at application startup (bootstrap)
def bootstrap() -> dict:
    session = create_db_session()
    repo = SqlTaskRepository(session)

    return {
        "create_task": functools.partial(create_task, repo),
        "complete_task": functools.partial(complete_task, repo),
    }

# In entrypoint
handlers = bootstrap()
task_id = handlers["create_task"](title="Write documentation")
```
