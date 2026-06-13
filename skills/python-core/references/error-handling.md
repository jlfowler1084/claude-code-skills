# 7. Error Handling

*Read this when writing exception hierarchies, deciding how tight to scope a try block, or implementing fallback chains.*

```python
# RULE: Specific exceptions, minimal try scope, chain with `from`

# Define domain exceptions in a module's exceptions.py
class AppError(Exception):
    """Base for all application errors."""

class NotFoundError(AppError):
    """Requested resource does not exist."""
    def __init__(self, resource_type: str, resource_id: str) -> None:
        self.resource_type = resource_type
        self.resource_id = resource_id
        super().__init__(f"{resource_type} {resource_id!r} not found")

class ValidationError(AppError):
    """Input failed validation."""
    def __init__(self, field: str, message: str) -> None:
        self.field = field
        super().__init__(f"Validation error on {field!r}: {message}")

# Catch specific, scope tight, chain exceptions
def load_config(path: Path) -> dict:
    try:
        text = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return {}  # Missing config is OK, use defaults
    except PermissionError as exc:
        raise AppError(f"Cannot read config at {path}") from exc

    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        raise ValidationError("config", f"Invalid JSON at line {exc.lineno}") from exc
```

**Avoid in new code:**
```python
# BAD: Bare except silences everything including KeyboardInterrupt
except:
    pass

# BAD: Swallowing errors with no logging
try:
    risky()
except SomeError:
    pass  # Errors should never pass silently

# BAD: Huge try blocks -- scope should be minimal
try:
    data = fetch()
    parsed = parse(data)
    result = transform(parsed)
    save(result)
except Exception:
    log("something failed")
```

**Exception: Pipeline / fallback architectures.** Broad `except Exception` catches ARE
acceptable when all of the following are true:

1. The code implements a deliberate fallback chain (try method A → catch → try method B)
2. Every catch block **logs the exception** (not silently swallowed)
3. The broad catch is documented with a comment explaining why it's broad

```python
# ACCEPTABLE: Fallback chain with logging
def extract_text(path: str, log=print) -> str:
    """Try multiple extraction methods, falling through on failure."""
    # Method 1: pdfplumber
    try:
        return extract_via_pdfplumber(path)
    except Exception as e:
        log(f"pdfplumber failed: {e}, trying PyMuPDF...")

    # Method 2: PyMuPDF
    try:
        return extract_via_pymupdf(path)
    except Exception as e:
        log(f"PyMuPDF failed: {e}, trying OCR...")

    # Method 3: OCR as last resort
    return extract_via_ocr(path)
```
