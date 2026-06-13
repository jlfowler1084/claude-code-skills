# 9. Async Patterns

*Read this when writing async functions, managing concurrency, or implementing async context managers and generators.*

```python
import asyncio
from collections.abc import Sequence

# Entry point -- one asyncio.run() at the top level
async def main() -> None:
    results = await asyncio.gather(
        fetch_data("url1"),
        fetch_data("url2"),
    )
    process_results(results)

asyncio.run(main())

# Controlled concurrency with semaphore
async def fetch_all(urls: Sequence[str], max_concurrent: int = 10) -> list[dict]:
    semaphore = asyncio.Semaphore(max_concurrent)

    async def fetch_one(url: str) -> dict:
        async with semaphore:
            return await fetch_data(url)

    return await asyncio.gather(*[fetch_one(u) for u in urls])

# Async context manager
from contextlib import asynccontextmanager

@asynccontextmanager
async def managed_session():
    session = await create_session()
    try:
        yield session
    finally:
        await session.close()

# Async generator for streaming
from collections.abc import AsyncIterator

async def stream_records(source) -> AsyncIterator[dict]:
    async for chunk in source.read_chunks():
        for record in parse_chunk(chunk):
            yield record
```
