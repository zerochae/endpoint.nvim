# FastAPI Framework Support

## Overview

The FastAPI Framework implementation provides comprehensive support for FastAPI applications, including async endpoints and router-based organization. It detects FastAPI projects and parses decorator patterns to extract API endpoint information.

## Framework Details

- **Name**: `fastapi`
- **Language**: Python
- **File Extensions**: `*.py`
- **Framework Class**: `FastApiFramework`

## Detection Strategy

### Dependency-Based Detection

The framework detects FastAPI projects by looking for specific dependencies in Python package files:

**Required Dependencies:**
- `fastapi`
- `FastAPI`

**Manifest Files Searched:**
- `requirements.txt`
- `pyproject.toml`
- `setup.py`
- `Pipfile`

### Detection Logic
```lua
-- Searches for FastAPI dependencies in Python package files
-- Returns true if any FastAPI-related dependency is found
```

## Parsing Strategy

### Annotation-Based Parsing (Decorator Parsing)

The framework uses decorator-based parsing to extract endpoint information from FastAPI decorators.

### Supported Decorators

| Decorator | HTTP Method | Example |
|-----------|-------------|---------|
| `@app.get` | GET | `@app.get("/users")` |
| `@app.post` | POST | `@app.post("/users")` |
| `@app.put` | PUT | `@app.put("/users/{user_id}")` |
| `@app.delete` | DELETE | `@app.delete("/users/{user_id}")` |
| `@app.patch` | PATCH | `@app.patch("/users/{user_id}")` |
| `@router.get` | GET | `@router.get("/items")` |
| `@router.post` | POST | `@router.post("/items")` |

### Path Extraction Patterns

The parser recognizes various path definition formats:

1. **Simple Path**: `@app.get("/users")`
2. **Single Quotes**: `@app.get('/users')`
3. **F-strings**: `@app.get(f"/users/{prefix}/items")`
4. **Router Paths**: `@router.get("/items")`

### Router Support

FastAPI's router-based organization is fully supported:

```python
from fastapi import APIRouter

router = APIRouter(prefix="/api/users")

@router.get("/")          # Final path: /api/users/
async def get_users():
    pass

@router.get("/{user_id}") # Final path: /api/users/{user_id}
async def get_user(user_id: int):
    pass
```

## Configuration Options

### File Processing
- **Include Patterns**: `*.py`
- **Exclude Patterns**:
  - `**/__pycache__` (Python cache)
  - `**/venv` (Virtual environment)
  - `**/.venv` (Virtual environment)
  - `**/site-packages` (Python packages)

### Search Options
- `--type py`: Optimizes search for Python files

### Pattern Matching
```lua
patterns = {
  GET = { "@app\\.get", "@router\\.get" },
  POST = { "@app\\.post", "@router\\.post" },
  PUT = { "@app\\.put", "@router\\.put" },
  DELETE = { "@app\\.delete", "@router\\.delete" },
  PATCH = { "@app\\.patch", "@router\\.patch" },
}
```

## Metadata Enhancement

### Framework-Specific Tags
- `python` (language)
- `fastapi` (framework)

### Metadata Fields
- `framework_version`: "fastapi"
- `language`: "python"

### Confidence Scoring
Base confidence: 0.7

**Confidence Boosts:**
- +0.15 for clear HTTP method detection
- +0.15 for clear path extraction

## Example Endpoint Structures

### Basic FastAPI Application
```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}
# Detected: GET /

@app.get("/users")
async def get_users():
    return {"users": []}
# Detected: GET /users

@app.post("/users")
async def create_user(user: dict):
    return user
# Detected: POST /users

@app.get("/users/{user_id}")
async def get_user(user_id: int):
    return {"user": {"id": user_id}}
# Detected: GET /users/{user_id}

@app.put("/users/{user_id}")
async def update_user(user_id: int, user: dict):
    return {"user_id": user_id, **user}
# Detected: PUT /users/{user_id}

@app.delete("/users/{user_id}")
async def delete_user(user_id: int):
    return {"deleted": user_id}
# Detected: DELETE /users/{user_id}
```

### Router-Based Organization
```python
from fastapi import APIRouter

# User router
user_router = APIRouter(prefix="/api/users", tags=["users"])

@user_router.get("/")
async def list_users():
    return {"users": []}
# Detected: GET /

@user_router.get("/{user_id}")
async def get_user(user_id: int):
    return {"user": {"id": user_id}}
# Detected: GET /{user_id}

# Item router
item_router = APIRouter(prefix="/api/items", tags=["items"])

@item_router.get("/")
async def list_items():
    return {"items": []}
# Detected: GET /

@item_router.post("/")
async def create_item(item: dict):
    return item
# Detected: POST /
```

### Advanced Path Patterns
```python
@app.get("/users/{user_id}/posts/{post_id}")
async def get_user_post(user_id: int, post_id: int):
    return {"user_id": user_id, "post_id": post_id}
# Detected: GET /users/{user_id}/posts/{post_id}

@app.get("/search")
async def search_users(q: str = ""):
    return {"query": q, "results": []}
# Detected: GET /search
```

## Troubleshooting

### Common Issues

1. **No Endpoints Detected**
   - Verify FastAPI dependency in `requirements.txt` or `pyproject.toml`
   - Check that decorators use proper FastAPI syntax
   - Ensure files have `.py` extensions

2. **Router Paths Not Combined**
   - Verify router prefix configuration
   - Check that `APIRouter` is properly imported

3. **Missing Async Functions**
   - Both sync and async functions are supported
   - Ensure decorators are directly above function definitions

### Debug Information

Enable framework debugging to see detection and parsing details:
```lua
-- In your Neovim config
vim.g.endpoint_debug = true
```

## Integration Notes

- Works with FastAPI 0.60+ (supports both legacy and modern syntax)
- Compatible with async/await and synchronous endpoints
- Supports both app-level and router-level decorators
- Handles path parameters and query parameters
- Automatically excludes Python cache and virtual environments
- Supports f-string path definitions
- Compatible with Pydantic models and dependency injection