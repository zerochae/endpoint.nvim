# Phoenix Framework Support

## Overview

The Phoenix Framework implementation provides comprehensive support for Phoenix applications, including router and controller-based organization. It detects Phoenix projects and parses various route definition patterns to extract API endpoint information.

## Framework Details

- **Name**: `phoenix`
- **Language**: Elixir
- **File Extensions**: `*.ex`, `*.exs`
- **Framework Class**: `PhoenixFramework`

## Detection Strategy

### Dependency-Based Detection

The framework detects Phoenix projects by looking for specific dependencies in Elixir package files:

**Required Dependencies:**
- `phoenix`
- `phoenix_live_view`

**Manifest Files Searched:**
- `mix.exs`
- `mix.lock`

> [!NOTE]
> Phoenix detection uses dependency-based strategy to search for Phoenix-related dependencies in Elixir package manifest files.

## Parsing Strategy

### Annotation-Based Parsing (Route Macro Parsing)

The framework uses route macro-based parsing to extract endpoint information from Phoenix route definitions.

### Supported Route Macros

| Macro | HTTP Method | Example |
|-------|-------------|---------|
| `get` | GET | `get "/users", UserController, :index` |
| `post` | POST | `post "/users", UserController, :create` |
| `put` | PUT | `put "/users/:id", UserController, :update` |
| `patch` | PATCH | `patch "/users/:id", UserController, :update` |
| `delete` | DELETE | `delete "/users/:id", UserController, :delete` |
| `resources` | Multiple | `resources "/users", UserController` |

### Path Extraction Patterns

The parser recognizes various path definition formats:

1. **Simple Path**: `get "/users", UserController, :index`
2. **Single Quotes**: `get '/users', UserController, :index`
3. **Resources**: `resources "/users", UserController`
4. **Scoped Routes**: `scope "/api" do ... end`

### Route Scoping Support

Phoenix's route scoping is fully supported:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  scope "/api", MyAppWeb do
    pipe_through :api

    scope "/v1" do
      resources "/users", UserController, except: [:new, :edit]
      # Final paths: /api/v1/users (GET, POST)
      # /api/v1/users/:id (GET, PUT, PATCH, DELETE)
    end
  end
end
```

> [!TIP]
> Route scopes are automatically detected and combined with nested routes.

## Configuration Options

### File Processing
- **Include Patterns**: `*.ex`, `*.exs`
- **Exclude Patterns**:
  - `**/_build` (Mix build output)
  - `**/deps` (Dependencies)
  - `**/priv` (Private assets)

### Search Options
- `--type elixir`: Optimizes search for Elixir files

### Pattern Matching
```lua
patterns = {
  GET = { "get\\s+", "resources\\s+" },
  POST = { "post\\s+", "resources\\s+" },
  PUT = { "put\\s+", "resources\\s+" },
  PATCH = { "patch\\s+", "resources\\s+" },
  DELETE = { "delete\\s+", "resources\\s+" },
}
```

## Metadata Enhancement

### Framework-Specific Tags
- `elixir` (language)
- `phoenix` (framework)

### Metadata Fields
- `framework_version`: "phoenix"
- `language`: "elixir"
- `controller`: Controller module name
- `action`: Action function name

### Confidence Scoring
Base confidence: 0.8

**Confidence Boosts:**
- +0.1 for well-formed paths (starting with `/`)
- +0.1 for standard HTTP methods

## Example Endpoint Structures

### Basic Phoenix Router
```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyAppWeb do
    pipe_through :api

    get "/", PageController, :index
    # Detected: GET /

    get "/users", UserController, :index
    # Detected: GET /users

    post "/users", UserController, :create
    # Detected: POST /users

    get "/users/:id", UserController, :show
    # Detected: GET /users/:id

    put "/users/:id", UserController, :update
    # Detected: PUT /users/:id

    delete "/users/:id", UserController, :delete
    # Detected: DELETE /users/:id
  end
end
```

### Resource-Based Routes
```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  scope "/api", MyAppWeb do
    pipe_through :api

    resources "/users", UserController
    # Detected: GET /api/users (index)
    # Detected: GET /api/users/:id (show)
    # Detected: POST /api/users (create)
    # Detected: PUT /api/users/:id (update)
    # Detected: PATCH /api/users/:id (update)
    # Detected: DELETE /api/users/:id (delete)

    resources "/users", UserController, only: [:index, :show]
    # Detected: GET /api/users (index)
    # Detected: GET /api/users/:id (show)

    resources "/posts", PostController, except: [:delete]
    # Detected: All except DELETE /api/posts/:id
  end
end
```

### Nested and Scoped Routes
```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  scope "/api", MyAppWeb do
    pipe_through :api

    scope "/v1" do
      resources "/users", V1.UserController do
        resources "/posts", V1.PostController
      end
    end
    # Detected: GET /api/v1/users
    # Detected: GET /api/v1/users/:user_id/posts
    # etc.

    scope "/admin" do
      resources "/users", Admin.UserController
    end
    # Detected: GET /api/admin/users
    # etc.
  end
end
```

### Advanced Route Patterns
```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  scope "/", MyAppWeb do
    pipe_through :api

    get "/users/:user_id/posts/:id", PostController, :show
    # Detected: GET /users/:user_id/posts/:id

    get "/search", SearchController, :index
    # Detected: GET /search

    forward "/graphql", Absinthe.Plug,
      schema: MyAppWeb.Schema
    # Detected: forward route (may not be parsed as standard HTTP)
  end
end
```

## Troubleshooting

### Common Issues

> [!WARNING]
> **No Endpoints Detected**
> - Verify Phoenix dependency in `mix.exs`
> - Check that routes use proper Phoenix syntax
> - Ensure files have `.ex` or `.exs` extensions

> [!CAUTION]
> **Scoped Routes Not Combined**
> - Verify proper `scope` block nesting
> - Check that scope paths are properly defined

> [!TIP]
> **Missing Resource Actions**
> - Ensure `resources` declarations are properly formatted
> - Check for restrictions with `only` or `except` options

### Debug Information

Enable framework debugging to see detection and parsing details:
```lua
-- In your Neovim config
vim.g.endpoint_debug = true
```

## Integration Notes

> [!INFO]
> - Works with Phoenix 1.5+
> - Compatible with Phoenix LiveView
> - Supports both traditional and resource-based routing
> - Handles nested resources and scoped routes
> - Automatically excludes build directories and dependencies
> - Supports pipeline and plug configurations
> - Compatible with Phoenix channels and LiveView routes