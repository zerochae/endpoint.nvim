# Gin Framework Support

## Overview

The Gin Framework implementation provides comprehensive support for Gin applications, including middleware and router group-based organization. It detects Gin projects and parses various route definition patterns to extract API endpoint information.

## Framework Details

- **Name**: `gin`
- **Language**: Go
- **File Extensions**: `*.go`
- **Framework Class**: `GinFramework`

## Detection Strategy

### Dependency-Based Detection

The framework detects Gin projects by looking for specific dependencies in Go module files:

**Required Dependencies:**
- `github.com/gin-gonic/gin`
- `gin-gonic/gin`

**Manifest Files Searched:**
- `go.mod`
- `go.sum`
- `Gopkg.toml`
- `vendor.json`

> [!NOTE]
> Gin detection uses dependency-based strategy to search for Gin-related dependencies in Go module manifest files.

## Parsing Strategy

### Annotation-Based Parsing (Route Method Parsing)

The framework uses route method-based parsing to extract endpoint information from Gin route definitions.

### Supported Route Methods

| Method | HTTP Method | Example |
|--------|-------------|---------|
| `router.GET` | GET | `router.GET("/users", handler)` |
| `router.POST` | POST | `router.POST("/users", handler)` |
| `router.PUT` | PUT | `router.PUT("/users/:id", handler)` |
| `router.DELETE` | DELETE | `router.DELETE("/users/:id", handler)` |
| `router.PATCH` | PATCH | `router.PATCH("/users/:id", handler)` |
| `router.Any` | Multiple | `router.Any("/users", handler)` |
| `group.GET` | GET | `group.GET("/profile", handler)` |

### Path Extraction Patterns

The parser recognizes various path definition formats:

1. **Simple Path**: `router.GET("/users", handler)`
2. **Backticks**: `router.GET(`/users`, handler)`
3. **Router Groups**: `v1.GET("/users", handler)`
4. **Parameter Paths**: `router.GET("/users/:id", handler)`

### Router Group Support

Gin's router group organization is fully supported:

```go
package main

import "github.com/gin-gonic/gin"

func main() {
    r := gin.Default()
    
    v1 := r.Group("/api/v1")
    {
        v1.GET("/users", getUsers)     // Final path: /api/v1/users
        v1.POST("/users", createUser)  // Final path: /api/v1/users
    }
}
```

> [!TIP]
> Router group prefixes are automatically detected and combined with route paths.

## Configuration Options

### File Processing
- **Include Patterns**: `*.go`
- **Exclude Patterns**:
  - `**/vendor` (Vendor dependencies)
  - `**/build` (Build output)
  - `**/.git` (Git repository)

### Search Options
- `--type go`: Optimizes search for Go files

### Pattern Matching
```lua
patterns = {
  GET = { "router\\.GET", "[a-zA-Z_][a-zA-Z0-9_]*\\.GET" },
  POST = { "router\\.POST", "[a-zA-Z_][a-zA-Z0-9_]*\\.POST" },
  PUT = { "router\\.PUT", "[a-zA-Z_][a-zA-Z0-9_]*\\.PUT" },
  DELETE = { "router\\.DELETE", "[a-zA-Z_][a-zA-Z0-9_]*\\.DELETE" },
  PATCH = { "router\\.PATCH", "[a-zA-Z_][a-zA-Z0-9_]*\\.PATCH" },
}
```

## Metadata Enhancement

### Framework-Specific Tags
- `go` (language)
- `gin` (framework)

### Metadata Fields
- `framework_version`: "gin"
- `language`: "go"

### Confidence Scoring
Base confidence: 0.8

**Confidence Boosts:**
- +0.1 for well-formed paths (starting with `/`)
- +0.1 for standard HTTP methods

## Example Endpoint Structures

### Basic Gin Application
```go
package main

import (
    "github.com/gin-gonic/gin"
    "net/http"
)

func main() {
    r := gin.Default()
    
    r.GET("/", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"message": "Hello World"})
    })
    // Detected: GET /
    
    r.GET("/users", getUsers)
    // Detected: GET /users
    
    r.POST("/users", createUser)
    // Detected: POST /users
    
    r.GET("/users/:id", getUser)
    // Detected: GET /users/:id
    
    r.PUT("/users/:id", updateUser)
    // Detected: PUT /users/:id
    
    r.DELETE("/users/:id", deleteUser)
    // Detected: DELETE /users/:id
    
    r.Run(":8080")
}
```

### Router Group Organization
```go
func main() {
    r := gin.Default()
    
    // API v1 group
    v1 := r.Group("/api/v1")
    {
        users := v1.Group("/users")
        {
            users.GET("/", listUsers)
            // Detected: GET /
            
            users.GET("/:id", getUser)
            // Detected: GET /:id
            
            users.POST("/", createUser)
            // Detected: POST /
        }
        
        posts := v1.Group("/posts")
        {
            posts.GET("/", listPosts)
            // Detected: GET /
            
            posts.POST("/", createPost)
            // Detected: POST /
        }
    }
}
```

### Advanced Route Patterns
```go
func setupRouter() *gin.Engine {
    r := gin.Default()
    
    r.GET("/users/:userId/posts/:postId", getUserPost)
    // Detected: GET /users/:userId/posts/:postId
    
    r.GET("/search", searchUsers)
    // Detected: GET /search
    
    r.Any("/webhook", handleWebhook)
    // Detected: ANY /webhook
    
    return r
}
```

## Troubleshooting

### Common Issues

> [!WARNING]
> **No Endpoints Detected**
> - Verify Gin dependency in `go.mod`
> - Check that routes use proper Gin syntax
> - Ensure files have `.go` extensions

> [!CAUTION]
> **Router Group Paths Not Combined**
> - Verify router group creation with `r.Group()`
> - Check that group variables are properly used

> [!TIP]
> **Missing Handler Functions**
> - Both inline and separate handler functions are supported
> - Ensure route definitions are in proper format

### Debug Information

Enable framework debugging to see detection and parsing details:
```lua
-- In your Neovim config
vim.g.endpoint_debug = true
```

## Integration Notes

> [!INFO]
> - Works with Gin v1.x
> - Compatible with Go modules and vendor directories
> - Supports router groups and middleware
> - Handles nested route structures and route parameters
> - Automatically excludes vendor dependencies and build directories
> - Supports inline and separate handler functions
> - Compatible with Gin middleware and custom middleware