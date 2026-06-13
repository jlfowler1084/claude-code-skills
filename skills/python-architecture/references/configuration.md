# 6. Configuration (12-Factor)

*Read this when setting up application configuration with pydantic-settings for environment variable loading.*

```python
# config.py
from pathlib import Path
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Required -- no default means it MUST be set
    database_url: str

    # Optional with sensible defaults
    debug: bool = False
    log_level: str = "INFO"
    batch_size: int = 100
    data_dir: Path = Path("data")

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
    }

# Usage -- create once at startup
settings = Settings()
```

**For existing projects using `settings.json`:** If the project already has a working
JSON-based config pattern, continue using it. `pydantic-settings` is recommended for
new projects; it's not worth migrating an existing config system that works.
