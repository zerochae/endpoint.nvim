# Flask Framework Support

## Overview

The Flask Framework implementation provides comprehensive support for Flask applications, including decorators and blueprint-based organization. It detects Flask projects and parses various route definition patterns to extract API endpoint information.

## Framework Details

- **Name**: `flask`
- **Language**: Python
- **File Extensions**: `*.py`
- **Framework Class**: `FlaskFramework`

## Detection Strategy

### Dependency-Based Detection

The framework detects Flask projects by looking for specific dependencies in Python package files:

**Required Dependencies:**
- `flask`
- `Flask`

**Manifest Files Searched:**
- `requirements.txt`
- `pyproject.toml`
- `setup.py`
- `Pipfile`

> [!NOTE]
> Flask detection uses dependency-based strategy to search for Flask-related dependencies in Python package manifest files.

## Parsing Strategy

### Annotation-Based Parsing (Decorator Parsing)

The framework uses decorator-based parsing to extract endpoint information from Flask route decorators.

### Supported Decorators

| Decorator | HTTP Method | Example |
|-----------|-------------|---------|
| `@app.route` | Multiple/Specified | `@app.route('/users', methods=['GET'])` |
| `@app.get` | GET | `@app.get('/users')` |
| `@app.post` | POST | `@app.post('/users')` |
| `@app.put` | PUT | `@app.put('/users/<id>')` |
| `@app.delete` | DELETE | `@app.delete('/users/<id>')` |
| `@app.patch` | PATCH | `@app.patch('/users/<id>')` |
| `@bp.route` | Multiple/Specified | `@bp.route('/items', methods=['GET'])` |

### Path Extraction Patterns

The parser recognizes various path definition formats:

1. **Simple Path**: `@app.route('/users')`
2. **Single Quotes**: `@app.route("/users")`
3. **Methods Parameter**: `@app.route('/users', methods=['GET', 'POST'])`
4. **Blueprint Routes**: `@bp.route('/items')`

### Blueprint Support

Flask's blueprint-based organization is fully supported:

```python
from flask import Blueprint

bp = Blueprint('users', __name__, url_prefix='/api/users')

@bp.route('/')                    # Final path: /api/users/
def get_users():
    pass

@bp.route('/<int:user_id>')      # Final path: /api/users/<int:user_id>
def get_user(user_id):
    pass
```

> [!TIP]
> Blueprint url_prefix is automatically detected and combined with route paths.

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
  GET = { "@app\\.get", "@bp\\.get", "@app\\.route.*GET", "@bp\\.route.*GET" },
  POST = { "@app\\.post", "@bp\\.post", "@app\\.route.*POST", "@bp\\.route.*POST" },
  PUT = { "@app\\.put", "@bp\\.put", "@app\\.route.*PUT", "@bp\\.route.*PUT" },
  DELETE = { "@app\\.delete", "@bp\\.delete", "@app\\.route.*DELETE", "@bp\\.route.*DELETE" },
  PATCH = { "@app\\.patch", "@bp\\.patch", "@app\\.route.*PATCH", "@bp\\.route.*PATCH" },
}
```

## Metadata Enhancement

### Framework-Specific Tags
- `python` (language)
- `flask` (framework)

### Metadata Fields
- `framework_version`: "flask"
- `language`: "python"

### Confidence Scoring
Base confidence: 0.8

**Confidence Boosts:**
- +0.1 for well-formed paths (starting with `/`)
- +0.1 for standard HTTP methods

## Example Endpoint Structures

### Basic Flask Application
```python
from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
    return 'Hello World'
# Detected: GET / (default method)

@app.route('/users')
def get_users():
    return {'users': []}
# Detected: GET /users

@app.route('/users', methods=['POST'])
def create_user():
    return request.json
# Detected: POST /users

@app.get('/users/<int:user_id>')
def get_user(user_id):
    return {'user': {'id': user_id}}
# Detected: GET /users/<int:user_id>

@app.put('/users/<int:user_id>')
def update_user(user_id):
    return {'user_id': user_id, **request.json}
# Detected: PUT /users/<int:user_id>

@app.delete('/users/<int:user_id>')
def delete_user(user_id):
    return {'deleted': user_id}
# Detected: DELETE /users/<int:user_id>
```

### Blueprint-Based Organization
```python
from flask import Blueprint

# User blueprint
user_bp = Blueprint('users', __name__, url_prefix='/api/users')

@user_bp.route('/')
def list_users():
    return {'users': []}
# Detected: GET /

@user_bp.route('/<int:user_id>')
def get_user(user_id):
    return {'user': {'id': user_id}}
# Detected: GET /<int:user_id>

# Item blueprint
item_bp = Blueprint('items', __name__, url_prefix='/api/items')

@item_bp.route('/')
def list_items():
    return {'items': []}
# Detected: GET /

@item_bp.route('/', methods=['POST'])
def create_item():
    return request.json
# Detected: POST /
```

### Advanced Path Patterns
```python
@app.route('/users/<int:user_id>/posts/<int:post_id>')
def get_user_post(user_id, post_id):
    return {'user_id': user_id, 'post_id': post_id}
# Detected: GET /users/<int:user_id>/posts/<int:post_id>

@app.route('/search')
def search_users():
    return {'query': request.args.get('q', ''), 'results': []}
# Detected: GET /search

@app.route('/users', methods=['GET', 'POST'])
def users():
    if request.method == 'GET':
        return {'users': []}
    else:
        return request.json
# Detected: GET /users, POST /users (multiple methods)
```

## Troubleshooting

### Common Issues

> [!WARNING]
> **No Endpoints Detected**
> - Verify Flask dependency in `requirements.txt` or `pyproject.toml`
> - Check that decorators use proper Flask syntax
> - Ensure files have `.py` extensions

> [!CAUTION]
> **Blueprint Paths Not Combined**
> - Verify blueprint url_prefix configuration
> - Check that `Blueprint` is properly imported

> [!TIP]
> **Missing Method-Specific Decorators**
> - Both `@app.route` and `@app.get` style decorators are supported
> - Ensure decorators are directly above function definitions

### Debug Information

Enable framework debugging to see detection and parsing details:
```lua
-- In your Neovim config
vim.g.endpoint_debug = true
```

## Integration Notes

> [!INFO]
> - Works with Flask 1.0+ (supports both legacy and modern syntax)
> - Compatible with Flask-RESTful extensions
> - Supports both app-level and blueprint-level decorators
> - Handles path parameters and query parameters
> - Automatically excludes Python cache and virtual environments
> - Supports multiple HTTP methods on single route
> - Compatible with Flask extensions and middleware