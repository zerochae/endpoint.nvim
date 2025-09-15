# Django Framework Support

> **Language** | **언어**
> - 🇺🇸 **English** (this file)
> - 🇰🇷 [**한국어**](./README.ko.md)

Django framework support for endpoint.nvim provides comprehensive endpoint discovery and navigation capabilities.

## Key Features

### 1. Automatic Endpoint Discovery

Analyzes Django project URLconf structure to automatically discover all endpoints.

#### Supported URL Patterns:
- **path()**: `path('users/', views.user_list, name='user_list')`
- **re_path()**: `re_path(r'^users/(?P<user_id>\d+)/$', views.user_detail)`
- **url()**: `url(r'^legacy/', views.legacy_view)` (legacy support)
- **include()**: `path('api/', include('api.urls'))` (recursive analysis)

#### Supported View Types:
- **Function-based views (FBV)**: `def user_list(request):`
- **Class-based views (CBV)**: `UserListView.as_view()`
- **Django REST Framework ViewSets**: `UserViewSet`
- **String references**: `'users.views.user_detail'`

### 2. Automatic ROOT_URLCONF Detection

Automatically finds ROOT_URLCONF from Django settings to determine entry points.

```python
# Auto-detected from settings.py
ROOT_URLCONF = 'myproject.urls'
```

### 3. HTTP Method-Specific Line Targeting

Navigate to the exact line where each HTTP method is implemented.

#### Class-Based Views (CBV)

```python
class UserCreateView(CreateView):
    def get(self, request):        # ← GET requests navigate to this line
        return JsonResponse({'form': 'create_form'})

    def post(self, request):       # ← POST requests navigate to this line
        return JsonResponse({'message': 'User created'})
```

- `GET /api/users/create/` → `def get(self, request):` line
- `POST /api/users/create/` → `def post(self, request):` line

#### Function-Based Views - With Conditionals

```python
def user_list(request):
    if request.method == 'GET':    # ← GET requests navigate to this line
        return JsonResponse({'users': []})
    elif request.method == 'POST': # ← POST requests navigate to this line
        return JsonResponse({'message': 'User created'})
```

- `GET /api/users/` → `if request.method == 'GET':` line
- `POST /api/users/` → `elif request.method == 'POST':` line

#### Function-Based Views - Without Conditionals

```python
def user_detail(request, pk):      # ← All HTTP methods navigate to this line
    return JsonResponse({'user_id': pk})
```

- `GET /api/users/1/` → `def user_detail(request, pk):` line
- `POST /api/users/1/` → `def user_detail(request, pk):` line

### 4. Django REST Framework (DRF) Support

#### ViewSet and Router Auto-Analysis

```python
# DRF Router auto-detection
router = DefaultRouter()
router.register(r'users', UserViewSet)

class UserViewSet(viewsets.ModelViewSet):
    def list(self, request):       # ← GET /api/users/
    def create(self, request):     # ← POST /api/users/
    def retrieve(self, request, pk): # ← GET /api/users/{pk}/
    def update(self, request, pk): # ← PUT /api/users/{pk}/
    def destroy(self, request, pk): # ← DELETE /api/users/{pk}/

    @action(detail=False, methods=['get'])
    def active(self, request):     # ← GET /api/users/active/
```

#### @api_view Decorator Support

```python
@api_view(['GET', 'POST'])
def api_endpoint(request):         # ← Both GET and POST navigate to this line
    if request.method == 'GET':    # ← GET requests navigate to this line
        return Response({'data': []})
    elif request.method == 'POST': # ← POST requests navigate to this line
        return Response({'created': True})
```

### 5. Customizable URL Parameter Display

Flexibly configure how URL parameters are displayed.

#### Configuration

```lua
require('endpoint').setup({
  frameworks = {
    django = {
      url_param_format = "%t:%v",    -- Content template: %v=variable name, %t=type
      url_param_fallback = "%v",     -- Template when type is unavailable
      url_param_brackets = "<>",     -- Bracket style
    }
  }
})
```

#### Display Style Examples

| Setting | Django Original | Result |
|---------|----------------|--------|
| `%t:%v` + `<>` | `<int:pk>` | `<int:pk>` |
| `%v:%t` + `{}` | `<int:pk>` | `{pk:int}` |
| `%v` + `[]` | `<int:pk>` | `[pk]` |
| `%t-%v` + `()` | `<int:pk>` | `(int-pk)` |

#### Supported Bracket Styles:
- `"{}"` → `{pk:int}`
- `"<>"` → `<int:pk>`
- `"[]"` → `[pk:int]`
- `"()"` → `(int:pk)`
- Custom: `"⟨⟩"` → `⟨pk:int⟩`

### 6. Intelligent Caching System

Provides intelligent caching system for performance optimization.

- **Full scan cache**: Scans and caches all endpoints at once
- **Method-based filtering**: Filters specific HTTP methods from cached results
- **Auto-invalidation**: Automatically invalidates cache after 30 seconds

## Supported Django Versions

- Django 2.0+
- Django REST Framework 3.0+

## File Structure Requirements

```
myproject/
├── settings.py          # ROOT_URLCONF setting required
├── urls.py             # Main URLconf
└── apps/
    └── users/
        ├── urls.py     # App-level URLconf
        └── views.py    # View implementations
```

## Configuration Examples

### Basic Configuration

```lua
require('endpoint').setup({
  frameworks = {
    django = {
      url_param_format = "%v:%t",      -- {pk:int} style
      url_param_fallback = "%v",       -- {pk} style
      url_param_brackets = "{}",       -- {} brackets
    }
  }
})
```

### Django-Friendly Configuration

```lua
require('endpoint').setup({
  frameworks = {
    django = {
      url_param_format = "%t:%v",      -- <int:pk> style (keeps Django original)
      url_param_fallback = "%v",       -- <pk> style
      url_param_brackets = "<>",       -- <> brackets
    }
  }
})
```

## Troubleshooting

### Endpoints Not Being Discovered

1. **Check ROOT_URLCONF**: Verify correct ROOT_URLCONF is set in `settings.py`
2. **Check file paths**: Ensure URLconf files are in correct locations
3. **Clear cache**: Run `:lua package.loaded['endpoint.frameworks.django'] = nil` and retry

### Wrong Line Navigation

1. **Reload plugin**: Restart Neovim or reapply configuration
2. **File sync**: Ensure modified files are saved

## Developer Information

Django framework support consists of these main components:

- **URL pattern parsing**: `parse_url_pattern()` function
- **View analysis**: `analyze_view_target()` function
- **CBV analysis**: `analyze_class_view()` function
- **Function analysis**: `analyze_function_view()` function
- **ViewSet analysis**: `analyze_viewset_class()` function
- **Endpoint generation**: `generate_view_endpoints()` function

For detailed implementation, see `lua/endpoint/frameworks/django/init.lua`.