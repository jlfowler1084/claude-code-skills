# 11. Naming Conventions

*Read this when naming any Python identifier: modules, classes, functions, constants, or type variables.*

| Type | Convention | Example |
|---|---|---|
| Module | `lower_with_under` | `user_service.py` |
| Package | `lower_with_under` | `data_access/` |
| Class | `CapWords` | `UserService` |
| Function / Method | `lower_with_under` | `get_active_users()` |
| Variable | `lower_with_under` | `total_count` |
| Constant | `CAPS_WITH_UNDER` | `MAX_RETRIES` |
| Internal / Private | `_leading_under` | `_parse_header()` |
| Type variable | `CapWords` or single letter | `T`, `KeyType` |
| Protocol | `CapWords` (noun/adjective) | `Readable`, `Serializable` |
