# 5. Generators and Itertools

*Read this when processing sequences, building data pipelines, or deciding between generators, list comprehensions, and materialised lists.*

Use generators by default for data pipelines. Only materialize to a list when you
need random access or know the data fits in memory.

```python
from collections.abc import Iterator, Iterable
from pathlib import Path
import itertools

# Generator for lazy file processing -- handles files of any size
def read_records(path: Path) -> Iterator[dict]:
    """Yield records one at a time without loading entire file."""
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                yield parse_record(line)

# Chain generators into pipelines
def pipeline(path: Path) -> Iterator[dict]:
    records = read_records(path)
    valid = (r for r in records if r.get("status") == "active")
    enriched = (enrich(r) for r in valid)
    return enriched

# Use itertools for common patterns
def batched(iterable: Iterable, n: int) -> Iterator[tuple]:
    """Batch items into groups of n (use itertools.batched in 3.12+)."""
    it = iter(iterable)
    while batch := tuple(itertools.islice(it, n)):
        yield batch

# Generator expression vs list comprehension
# GOOD: Generator when you only iterate once
total = sum(item.price for item in catalog if item.in_stock)

# GOOD: List when you need len(), indexing, or multiple passes
active_users = [u for u in users if u.is_active]
print(f"Found {len(active_users)} active users")
```
