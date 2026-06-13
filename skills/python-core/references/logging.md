# 10. Logging

*Read this when adding logging to a new module, deciding between the logging module and print, or writing functions that route output to callers.*

**New modules:** Use the `logging` module with module-level loggers.
**Existing code with log callbacks:** If a file uses `log()` callback parameters
(function-passing pattern for dual CLI/GUI output), continue using that pattern.
**CLI tools:** `print()` for intentional interactive user output is fine. The rule
is about diagnostic/debug output, not user-facing messages.

```python
import logging

# Module-level logger for new code
logger = logging.getLogger(__name__)

# Use lazy formatting (% style) -- args only evaluated if level is enabled
logger.debug("Processing batch %s with %d items", batch_id, len(items))
logger.info("User %s authenticated successfully", user_id)
logger.warning("Retry %d/%d for %s", attempt, max_retries, operation)
logger.error("Failed to process %s: %s", item_id, error)
logger.exception("Unexpected error in %s", func_name)  # auto-includes traceback

# Structured logging setup (configure once in entrypoint, not in library code)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
```

**Recognized log callback pattern** (used in projects with dual CLI/GUI output):
```python
# ACCEPTABLE: Function-passing pattern for flexible output routing
def process_batch(input_dir: str, output_dir: str, log=print) -> dict:
    """Process a batch of files. log parameter routes output to caller's choice."""
    log(f"Processing {input_dir}...")
    for file in os.listdir(input_dir):
        try:
            result = process_file(file)
            log(f"  OK: {file}")
        except Exception as e:
            log(f"  FAIL: {file}: {e}")
    return summary
```

**What to avoid (in new modules):**
```python
# BAD: f-string in logger -- evaluated even if level is disabled
logger.info(f"User {user_id}")
# BAD: Root logger -- loses module context
logging.info("message")
```
