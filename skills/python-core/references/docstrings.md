# 12. Docstrings (Google Style)

*Read this when writing docstrings for public functions, classes, or modules.*

```python
def execute_pipeline(
    source: Path,
    output: Path,
    *,
    batch_size: int = 100,
    dry_run: bool = False,
) -> dict[str, int]:
    """Execute the data processing pipeline.

    Reads records from source, applies transformations in batches,
    and writes results to output. Skips invalid records with a warning.

    Args:
        source: Path to input data file (CSV or JSON).
        output: Path for processed output.
        batch_size: Number of records per processing batch.
        dry_run: If True, validate without writing output.

    Returns:
        Summary dict with keys 'processed', 'skipped', 'errors'.

    Raises:
        FileNotFoundError: If source does not exist.
        ValidationError: If source format is unsupported.

    Example:
        >>> result = execute_pipeline(Path("in.csv"), Path("out.json"))
        >>> print(result["processed"])
        42
    """
```
