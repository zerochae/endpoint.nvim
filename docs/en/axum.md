# Axum Framework Support

## Overview

The Axum Framework implementation provides comprehensive support for Axum applications, including handlers and router-based organization. It detects Axum projects and parses various route definition patterns to extract API endpoint information.

## Framework Details

- **Name**: `axum`
- **Language**: Rust
- **File Extensions**: `*.rs`
- **Framework Class**: `AxumFramework`

## Detection Strategy

### Dependency-Based Detection

The framework detects Axum projects by looking for specific dependencies in Rust package files:

**Required Dependencies:**
- `axum`
- `axum-core`

**Manifest Files Searched:**
- `Cargo.toml`
- `Cargo.lock`

> [!NOTE]
> Axum detection uses dependency-based strategy to search for Axum-related dependencies in Rust package manifest files.

## Parsing Strategy

### Annotation-Based Parsing (Route Method Parsing)

The framework uses route method-based parsing to extract endpoint information from Axum route definitions.

### Supported Route Methods

| Method | HTTP Method | Example |
|--------|-------------|---------|
| `get` | GET | `get("/users", handler)` |
| `post` | POST | `post("/users", handler)` |
| `put` | PUT | `put("/users/:id", handler)` |
| `delete` | DELETE | `delete("/users/:id", handler)` |
| `patch` | PATCH | `patch("/users/:id", handler)` |
| `any` | Multiple | `any("/users", handler)` |

### Path Extraction Patterns

The parser recognizes various path definition formats:

1. **Simple Path**: `get("/users", handler)`
2. **Single Quotes**: `get('/users', handler)`
3. **Router Nesting**: `Router::new().route("/users", get(handler))`
4. **Parameter Paths**: `get("/users/:id", handler)`

### Router Nesting Support

Axum's router nesting is fully supported:

```rust
use axum::{Router, routing::get};

fn create_router() -> Router {
    Router::new()
        .nest("/api/v1", api_v1_routes())
        .nest("/api/v2", api_v2_routes())
}

fn api_v1_routes() -> Router {
    Router::new()
        .route("/users", get(list_users))     // Final path: /api/v1/users
        .route("/users/:id", get(get_user))   // Final path: /api/v1/users/:id
}
```

> [!TIP]
> Router nesting with `.nest()` is automatically detected and paths are combined correctly.

## Configuration Options

### File Processing
- **Include Patterns**: `*.rs`
- **Exclude Patterns**:
  - `**/target` (Cargo build output)
  - `**/.cargo` (Cargo cache)

### Search Options
- `--type rust`: Optimizes search for Rust files

### Pattern Matching
```lua
patterns = {
  GET = { "get\\s*\\(", "\\.route\\s*\\(.*get\\s*\\(" },
  POST = { "post\\s*\\(", "\\.route\\s*\\(.*post\\s*\\(" },
  PUT = { "put\\s*\\(", "\\.route\\s*\\(.*put\\s*\\(" },
  DELETE = { "delete\\s*\\(", "\\.route\\s*\\(.*delete\\s*\\(" },
  PATCH = { "patch\\s*\\(", "\\.route\\s*\\(.*patch\\s*\\(" },
}
```

## Metadata Enhancement

### Framework-Specific Tags
- `rust` (language)
- `axum` (framework)

### Metadata Fields
- `framework_version`: "axum"
- `language`: "rust"

### Confidence Scoring
Base confidence: 0.8

**Confidence Boosts:**
- +0.1 for well-formed paths (starting with `/`)
- +0.1 for standard HTTP methods

## Example Endpoint Structures

### Basic Axum Application
```rust
use axum::{
    routing::{get, post, put, delete},
    http::StatusCode,
    Json, Router,
};
use serde_json::{json, Value};

async fn root() -> Json<Value> {
    Json(json!({ "message": "Hello World" }))
}

async fn list_users() -> Json<Value> {
    Json(json!({ "users": [] }))
}

async fn create_user() -> StatusCode {
    StatusCode::CREATED
}

async fn get_user() -> Json<Value> {
    Json(json!({ "user": { "id": 1 } }))
}

async fn update_user() -> Json<Value> {
    Json(json!({ "updated": true }))
}

async fn delete_user() -> StatusCode {
    StatusCode::NO_CONTENT
}

fn create_router() -> Router {
    Router::new()
        .route("/", get(root))
        // Detected: GET /
        .route("/users", get(list_users))
        // Detected: GET /users
        .route("/users", post(create_user))
        // Detected: POST /users
        .route("/users/:id", get(get_user))
        // Detected: GET /users/:id
        .route("/users/:id", put(update_user))
        // Detected: PUT /users/:id
        .route("/users/:id", delete(delete_user))
        // Detected: DELETE /users/:id
}
```

### Router Nesting Organization
```rust
use axum::{Router, routing::get};

fn create_app() -> Router {
    Router::new()
        .nest("/api", api_routes())
}

fn api_routes() -> Router {
    Router::new()
        .nest("/v1", v1_routes())
        .nest("/v2", v2_routes())
}

fn v1_routes() -> Router {
    Router::new()
        .nest("/users", user_routes())
        .nest("/posts", post_routes())
}

fn user_routes() -> Router {
    Router::new()
        .route("/", get(list_users))
        // Detected: GET /
        .route("/:id", get(get_user))
        // Detected: GET /:id
        .route("/", post(create_user))
        // Detected: POST /
}

fn post_routes() -> Router {
    Router::new()
        .route("/", get(list_posts))
        // Detected: GET /
        .route("/", post(create_post))
        // Detected: POST /
}
```

### Advanced Route Patterns
```rust
fn create_router() -> Router {
    Router::new()
        .route("/users/:user_id/posts/:post_id", get(get_user_post))
        // Detected: GET /users/:user_id/posts/:post_id
        .route("/search", get(search_users))
        // Detected: GET /search
        .route("/webhook", axum::routing::any(handle_webhook))
        // Detected: ANY /webhook
}
```

## Troubleshooting

### Common Issues

> [!WARNING]
> **No Endpoints Detected**
> - Verify Axum dependency in `Cargo.toml`
> - Check that routes use proper Axum syntax
> - Ensure files have `.rs` extensions

> [!CAUTION]
> **Nested Routes Not Combined**
> - Verify router nesting with `.nest()`
> - Check that nested routers are properly structured

> [!TIP]
> **Missing Handler Functions**
> - Ensure handler functions are properly referenced
> - Check that routing methods are imported from `axum::routing`

### Debug Information

Enable framework debugging to see detection and parsing details:
```lua
-- In your Neovim config
vim.g.endpoint_debug = true
```

## Integration Notes

> [!INFO]
> - Works with Axum 0.6+
> - Compatible with Tokio async runtime
> - Supports nested routers and middleware
> - Handles route parameters and extractors
> - Automatically excludes Cargo build directories
> - Supports tower middleware and services
> - Compatible with serde serialization and custom extractors