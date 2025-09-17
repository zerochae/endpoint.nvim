# Django Framework Support

## Overview

The Django Framework implementation provides comprehensive support for Django applications, including URL patterns and view-based organization. It detects Django projects and parses various URL definition patterns to extract API endpoint information.

## Framework Details

- **Name**: `django`
- **Language**: Python
- **File Extensions**: `*.py`
- **Framework Class**: `DjangoFramework`

## Detection Strategy

### Dependency-Based Detection

The framework detects Django projects by looking for specific dependencies in Python package files:

**Required Dependencies:**
- `django`
- `Django`

**Manifest Files Searched:**
- `requirements.txt`
- `pyproject.toml`
- `setup.py`
- `Pipfile`
- `manage.py`
- `settings.py`

> [!NOTE]
> Django detection uses dependency-based strategy to search for Django-related dependencies in Python package manifest files and Django-specific files.

## Parsing Strategy

### Annotation-Based Parsing (URL Pattern Parsing)

The framework uses URL pattern-based parsing to extract endpoint information from Django URL configurations.

### Supported URL Patterns

| Pattern Type | HTTP Method | Example |
|--------------|-------------|---------|
| `path()` | Multiple | `path('users/', views.user_list)` |
| `re_path()` | Multiple | `re_path(r'^users/$', views.user_list)` |
| `url()` | Multiple | `url(r'^users/$', views.user_list)` |
| Class-based views | Multiple | `path('users/', UserListView.as_view())` |

### Path Extraction Patterns

The parser recognizes various path definition formats:

1. **Simple Path**: `path('users/', views.user_list)`
2. **Single Quotes**: `path("users/", views.user_list)`
3. **Regex Path**: `re_path(r'^users/(?P<id>\d+)/$', views.user_detail)`
4. **Include Patterns**: `path('api/', include('api.urls'))`

### URL Include Support

Django's URL include pattern is supported:

```python
# main/urls.py
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),
    path('api/posts/', include('posts.urls')),
]

# users/urls.py
urlpatterns = [
    path('', views.user_list),           # Final path: /api/users/
    path('<int:pk>/', views.user_detail), # Final path: /api/users/<int:pk>/
]
```

> [!TIP]
> URL include paths are automatically detected and combined with nested patterns.

## Configuration Options

### File Processing
- **Include Patterns**: `*.py`
- **Exclude Patterns**:
  - `**/__pycache__` (Python cache)
  - `**/venv` (Virtual environment)
  - `**/.venv` (Virtual environment)
  - `**/site-packages` (Python packages)
  - `**/migrations` (Django migrations)

### Search Options
- `--type py`: Optimizes search for Python files

### Pattern Matching
```lua
patterns = {
  GET = { "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(" },
  POST = { "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(" },
  PUT = { "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(" },
  DELETE = { "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(" },
  PATCH = { "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(" },
}
```

## Metadata Enhancement

### Framework-Specific Tags
- `python` (language)
- `django` (framework)

### Metadata Fields
- `framework_version`: "django"
- `language`: "python"
- `view_name`: View function or class name
- `app_name`: Django app name (if detectable)

### Confidence Scoring
Base confidence: 0.7

**Confidence Boosts:**
- +0.15 for clear view function detection
- +0.15 for well-formed URL patterns

## Example Endpoint Structures

### Function-Based Views
```python
from django.urls import path
from . import views

urlpatterns = [
    path('', views.user_list, name='user-list'),
    # Detected: GET/POST /users/ (function-based)
    
    path('<int:pk>/', views.user_detail, name='user-detail'),
    # Detected: GET/PUT/DELETE /users/<int:pk>/
    
    path('search/', views.search_users, name='user-search'),
    # Detected: GET /users/search/
]
```

### Class-Based Views
```python
from django.urls import path
from .views import UserListView, UserDetailView

urlpatterns = [
    path('', UserListView.as_view(), name='user-list'),
    # Detected: GET/POST /users/ (class-based)
    
    path('<int:pk>/', UserDetailView.as_view(), name='user-detail'),
    # Detected: GET/PUT/DELETE /users/<int:pk>/
]
```

### Django REST Framework
```python
from rest_framework.routers import DefaultRouter
from .views import UserViewSet

router = DefaultRouter()
router.register(r'users', UserViewSet)
urlpatterns = router.urls
# Detected: Multiple RESTful endpoints for /users/
```

### Advanced URL Patterns
```python
from django.urls import path, re_path, include

urlpatterns = [
    path('users/<int:user_id>/posts/<int:post_id>/', 
         views.user_post_detail),
    # Detected: GET/PUT/DELETE /users/<int:user_id>/posts/<int:post_id>/
    
    re_path(r'^search/(?P<query>[\w-]+)/$', views.search),
    # Detected: GET /search/<query>/
    
    path('api/v1/', include('api.urls')),
    # Detected: Includes from api.urls with /api/v1/ prefix
]
```

## Troubleshooting

### Common Issues

> [!WARNING]
> **No Endpoints Detected**
> - Verify Django dependency in `requirements.txt` or `pyproject.toml`
> - Check that URL patterns use proper Django syntax
> - Ensure files have `.py` extensions and contain `urlpatterns`

> [!CAUTION]
> **Include Paths Not Combined**
> - Verify `include()` statements are properly formatted
> - Check that included URL files exist and are accessible

> [!TIP]
> **Missing ViewSet Endpoints**
> - DRF ViewSets may not be detected in URL files
> - Check for router registrations and custom URL patterns

### Debug Information

Enable framework debugging to see detection and parsing details:
```lua
-- In your Neovim config
vim.g.endpoint_debug = true
```

## Integration Notes

> [!INFO]
> - Works with Django 2.x, 3.x, and 4.x
> - Compatible with Django REST Framework
> - Supports both function-based and class-based views
> - Handles URL includes and nested patterns
> - Automatically excludes Django migrations and Python cache
> - Supports regex URL patterns
> - Compatible with Django apps and project structure