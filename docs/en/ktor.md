# Ktor Framework Support

## Overview

The Ktor Framework implementation provides comprehensive support for Ktor applications, including routing DSL and feature-based organization. It detects Ktor projects and parses various route definition patterns to extract API endpoint information.

## Framework Details

- **Name**: `ktor`
- **Language**: Kotlin
- **File Extensions**: `*.kt`
- **Framework Class**: `KtorFramework`

## Detection Strategy

### Dependency-Based Detection

The framework detects Ktor projects by looking for specific dependencies in Kotlin/JVM build files:

**Required Dependencies:**
- `io.ktor:ktor-server-core`
- `ktor-server-core`
- `ktor-server`

**Manifest Files Searched:**
- `build.gradle.kts`
- `build.gradle`
- `pom.xml`

> [!NOTE]
> Ktor detection uses dependency-based strategy to search for Ktor-related dependencies in Kotlin/JVM build manifest files.

## Parsing Strategy

### Annotation-Based Parsing (Routing DSL Parsing)

The framework uses routing DSL-based parsing to extract endpoint information from Ktor route definitions.

### Supported Routing Methods

| Method | HTTP Method | Example |
|--------|-------------|---------|
| `get` | GET | `get("/users") { ... }` |
| `post` | POST | `post("/users") { ... }` |
| `put` | PUT | `put("/users/{id}") { ... }` |
| `delete` | DELETE | `delete("/users/{id}") { ... }` |
| `patch` | PATCH | `patch("/users/{id}") { ... }` |
| `route` | Multiple | `route("/api") { ... }` |

### Path Extraction Patterns

The parser recognizes various path definition formats:

1. **Simple Path**: `get("/users") { ... }`
2. **Single Quotes**: `get('/users') { ... }`
3. **Route Groups**: `route("/api") { get("/users") { ... } }`
4. **Parameter Paths**: `get("/users/{id}") { ... }`

### Route Nesting Support

Ktor's routing DSL nesting is fully supported:

```kotlin
import io.ktor.server.routing.*
import io.ktor.server.application.*

fun Application.configureRouting() {
    routing {
        route("/api/v1") {
            route("/users") {
                get {
                    // Final path: /api/v1/users
                }
                post {
                    // Final path: /api/v1/users
                }
                get("/{id}") {
                    // Final path: /api/v1/users/{id}
                }
            }
        }
    }
}
```

> [!TIP]
> Nested route blocks are automatically detected and paths are combined correctly.

## Configuration Options

### File Processing
- **Include Patterns**: `*.kt`
- **Exclude Patterns**:
  - `**/build` (Build output)
  - `**/.gradle` (Gradle cache)
  - `**/target` (Maven target)

### Search Options
- `--type kotlin`: Optimizes search for Kotlin files

### Pattern Matching
```lua
patterns = {
  GET = { "get\\s*\\(", "get\\s*\\{" },
  POST = { "post\\s*\\(", "post\\s*\\{" },
  PUT = { "put\\s*\\(", "put\\s*\\{" },
  DELETE = { "delete\\s*\\(", "delete\\s*\\{" },
  PATCH = { "patch\\s*\\(", "patch\\s*\\{" },
}
```

## Metadata Enhancement

### Framework-Specific Tags
- `kotlin` (language)
- `ktor` (framework)

### Metadata Fields
- `framework_version`: "ktor"
- `language`: "kotlin"

### Confidence Scoring
Base confidence: 0.8

**Confidence Boosts:**
- +0.1 for well-formed paths (starting with `/`)
- +0.1 for standard HTTP methods

## Example Endpoint Structures

### Basic Ktor Application
```kotlin
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.plugins.contentnegotiation.*

fun Application.configureRouting() {
    install(ContentNegotiation) {
        json()
    }
    
    routing {
        get("/") {
            call.respondText("Hello World!")
        }
        // Detected: GET /
        
        get("/users") {
            call.respond(mapOf("users" to listOf<String>()))
        }
        // Detected: GET /users
        
        post("/users") {
            call.respond(mapOf("created" to true))
        }
        // Detected: POST /users
        
        get("/users/{id}") {
            val id = call.parameters["id"]
            call.respond(mapOf("user" to mapOf("id" to id)))
        }
        // Detected: GET /users/{id}
        
        put("/users/{id}") {
            val id = call.parameters["id"]
            call.respond(mapOf("updated" to id))
        }
        // Detected: PUT /users/{id}
        
        delete("/users/{id}") {
            val id = call.parameters["id"]
            call.respond(mapOf("deleted" to id))
        }
        // Detected: DELETE /users/{id}
    }
}
```

### Nested Route Organization
```kotlin
fun Application.configureRouting() {
    routing {
        route("/api") {
            route("/v1") {
                route("/users") {
                    get {
                        call.respond(mapOf("users" to listOf<String>()))
                    }
                    // Detected: GET /
                    
                    get("/{id}") {
                        val id = call.parameters["id"]
                        call.respond(mapOf("user" to mapOf("id" to id)))
                    }
                    // Detected: GET /{id}
                    
                    post {
                        call.respond(mapOf("created" to true))
                    }
                    // Detected: POST /
                }
                
                route("/posts") {
                    get {
                        call.respond(mapOf("posts" to listOf<String>()))
                    }
                    // Detected: GET /
                    
                    post {
                        call.respond(mapOf("created" to true))
                    }
                    // Detected: POST /
                }
            }
        }
    }
}
```

### Advanced Route Patterns
```kotlin
fun Application.configureRouting() {
    routing {
        get("/users/{userId}/posts/{postId}") {
            val userId = call.parameters["userId"]
            val postId = call.parameters["postId"]
            call.respond(mapOf("userId" to userId, "postId" to postId))
        }
        // Detected: GET /users/{userId}/posts/{postId}
        
        get("/search") {
            val query = call.request.queryParameters["q"] ?: ""
            call.respond(mapOf("query" to query, "results" to listOf<String>()))
        }
        // Detected: GET /search
    }
}
```

## Troubleshooting

### Common Issues

> [!WARNING]
> **No Endpoints Detected**
> - Verify Ktor dependencies in `build.gradle.kts` or `pom.xml`
> - Check that routing DSL uses proper Ktor syntax
> - Ensure files have `.kt` extensions

> [!CAUTION]
> **Nested Routes Not Combined**
> - Verify proper `route` block nesting
> - Check that routing DSL is properly structured

> [!TIP]
> **Missing Route Handlers**
> - Ensure route handlers are defined within routing blocks
> - Check that HTTP method functions are properly called

### Debug Information

Enable framework debugging to see detection and parsing details:
```lua
-- In your Neovim config
vim.g.endpoint_debug = true
```

## Integration Notes

> [!INFO]
> - Works with Ktor 2.x
> - Compatible with Kotlin/JVM and Kotlin/Native
> - Supports nested routing DSL and features
> - Handles route parameters and query parameters
> - Automatically excludes build directories and cache
> - Supports content negotiation and serialization
> - Compatible with Ktor plugins and custom features