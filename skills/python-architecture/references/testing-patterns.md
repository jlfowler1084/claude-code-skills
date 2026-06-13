# 7. Testing Patterns

*Read this when organizing tests, choosing between fakes and mocks, or structuring the test pyramid.*

## Test Pyramid

- **Unit tests** (many): Test domain logic and service handlers with fakes. Fast, no I/O.
- **Integration tests** (some): Test adapters against real infrastructure (DB, filesystem).
- **E2E tests** (few): Test through the actual API/CLI. Slow but high confidence.

## Fakes Over Mocks

Prefer fakes (simple in-memory implementations) over `unittest.mock`. Fakes catch interface
drift; mocks silently accept anything.

```python
# tests/conftest.py
import pytest
from domain.model import Task

@pytest.fixture
def fake_repo():
    return FakeTaskRepository()

@pytest.fixture
def sample_task():
    return Task(id="task-1", title="Test task")

# tests/unit/test_handlers.py
def test_create_task(fake_repo):
    task_id = create_task(fake_repo, title="Write docs")
    assert fake_repo.get(task_id) is not None
    assert fake_repo.get(task_id).title == "Write docs"

def test_complete_nonexistent_task_raises(fake_repo):
    with pytest.raises(NotFoundError):
        complete_task(fake_repo, "nonexistent-id")

def test_complete_task_changes_status(fake_repo, sample_task):
    fake_repo.add(sample_task)
    complete_task(fake_repo, sample_task.id)
    assert fake_repo.get(sample_task.id).status == "completed"
```

## Parametrize for Coverage

```python
import pytest

@pytest.mark.parametrize("status,can_complete", [
    ("pending", True),
    ("completed", False),
    ("cancelled", False),
])
def test_task_completion_rules(status, can_complete):
    task = Task(status=status)
    if can_complete:
        task.complete()
        assert task.status == "completed"
    else:
        with pytest.raises(InvalidStateError):
            task.complete()
```

## Test File Organization

```
tests/
├── conftest.py           # Shared fixtures (fake_repo, sample data, db session)
├── unit/
│   ├── conftest.py       # Unit-specific fixtures
│   ├── test_model.py     # Domain entity tests
│   ├── test_handlers.py  # Service layer with fakes
│   └── test_validators.py
├── integration/
│   ├── conftest.py       # DB fixtures, file system setup
│   ├── test_repository.py
│   └── test_orm.py
└── e2e/
    ├── conftest.py       # Running app fixture
    └── test_api.py
```
