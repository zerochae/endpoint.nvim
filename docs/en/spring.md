# Spring Framework Support

## Overview

The Spring Framework implementation provides comprehensive support for Spring Boot applications, including REST controllers and web endpoints. It detects Spring projects and parses various annotation patterns to extract API endpoint information.

## Framework Details

- **Name**: `spring`
- **Language**: Java, Kotlin
- **File Extensions**: `*.java`, `*.kt`
- **Framework Class**: `SpringFramework`

## Detection Strategy

### Dependency-Based Detection

The framework detects Spring projects by looking for specific dependencies in build files:

**Required Dependencies:**
- `spring-web`
- `spring-boot`
- `springframework`

**Manifest Files Searched:**
- `pom.xml` (Maven)
- `build.gradle` (Gradle)
- `build.gradle.kts` (Kotlin DSL)

> [!NOTE]
> Spring detection uses dependency-based strategy to search for Spring-related dependencies in Java/JVM build manifest files.


## Parsing Strategy

### Annotation-Based Parsing

The framework uses annotation-based parsing to extract endpoint information from Spring annotations.

### Supported Annotations

| Annotation | HTTP Method | Example |
|------------|-------------|---------|
| `@GetMapping` | GET | `@GetMapping("/users")` |
| `@PostMapping` | POST | `@PostMapping("/users")` |
| `@PutMapping` | PUT | `@PutMapping("/users/{id}")` |
| `@DeleteMapping` | DELETE | `@DeleteMapping("/users/{id}")` |
| `@PatchMapping` | PATCH | `@PatchMapping("/users/{id}")` |
| `@RequestMapping` | Various | `@RequestMapping(value="/users", method=RequestMethod.GET)` |

### Path Extraction Patterns

The parser recognizes various path definition formats:

1. **Simple Path**: `@GetMapping("/users")`
2. **Value Parameter**: `@RequestMapping(value = "/users")`
3. **Path Parameter**: `@RequestMapping(path = "/users")`
4. **Single Quotes**: `@GetMapping('/users')`

### Controller Base Path Support

The framework automatically detects and combines controller-level `@RequestMapping` annotations with method-level mappings:

```java
@RestController
@RequestMapping("/api/users")  // Base path
public class UserController {

    @GetMapping("/profile")     // Method path
    public User getProfile() {  // Final path: /api/users/profile
        // ...
    }
}
```

> [!TIP]
> Controller base paths are automatically detected and combined with method paths.

## Configuration Options

### File Processing
- **Include Patterns**: `*.java`, `*.kt`
- **Exclude Patterns**:
  - `**/target` (Maven build directory)
  - `**/build` (Gradle build directory)
  - `**/.gradle` (Gradle cache)

### Search Options
- `--case-sensitive`: Preserves Java annotation case sensitivity
- `--type java`: Optimizes search for Java files
- `--type kotlin`: Optimizes search for Kotlin files

### Pattern Matching
```lua
patterns = {
  GET = { "@GetMapping", "@RequestMapping.*method.*=.*GET" },
  POST = { "@PostMapping", "@RequestMapping.*method.*=.*POST" },
  PUT = { "@PutMapping", "@RequestMapping.*method.*=.*PUT" },
  DELETE = { "@DeleteMapping", "@RequestMapping.*method.*=.*DELETE" },
  PATCH = { "@PatchMapping", "@RequestMapping.*method.*=.*PATCH" },
}
```

## Metadata Enhancement

### Framework-Specific Tags
- `java` or `kotlin` (language)
- `spring` (framework)

### Metadata Fields
- `framework_version`: "spring"
- `language`: "java" or "kotlin"
- `controller_base_path`: Base path from `@RequestMapping`
- `controller_name`: Controller class name

### Confidence Scoring
Base confidence: 0.8

**Confidence Boosts:**
- +0.1 for well-formed paths (starting with `/`)
- +0.1 for standard HTTP methods

## Example Endpoint Structures

### Basic REST Controller
```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping
    public List<User> getAllUsers() { }
    // Detected: GET /api/users

    @GetMapping("/{id}")
    public User getUser(@PathVariable Long id) { }
    // Detected: GET /api/users/{id}

    @PostMapping
    public User createUser(@RequestBody User user) { }
    // Detected: POST /api/users

    @PutMapping("/{id}")
    public User updateUser(@PathVariable Long id, @RequestBody User user) { }
    // Detected: PUT /api/users/{id}

    @DeleteMapping("/{id}")
    public void deleteUser(@PathVariable Long id) { }
    // Detected: DELETE /api/users/{id}
}
```

### Advanced RequestMapping
```java
@RestController
public class AdvancedController {

    @RequestMapping(value = "/search", method = RequestMethod.GET)
    public List<User> searchUsers() { }
    // Detected: GET /search

    @RequestMapping(path = "/batch", method = RequestMethod.POST)
    public void batchProcess() { }
    // Detected: POST /batch
}
```

### Advanced Route Patterns
```java
@RestController
@RequestMapping("/api/v1")
public class ApiController {

    @GetMapping("/users/{userId}/posts/{postId}")
    public Post getUserPost(@PathVariable Long userId, @PathVariable Long postId) {
        return postService.getUserPost(userId, postId);
    }
    // Detected: GET /api/v1/users/{userId}/posts/{postId}

    @GetMapping("/search")
    public List<User> search(@RequestParam String q) {
        return userService.search(q);
    }
    // Detected: GET /api/v1/search
}
```

## Troubleshooting

### Common Issues

> [!WARNING]
> **No Endpoints Detected**
> - Verify Spring dependencies in `pom.xml` or `build.gradle`
> - Check that controller classes use proper annotations
> - Ensure files have `.java` or `.kt` extensions

> [!CAUTION]
> **Incorrect Paths**
> - Verify `@RequestMapping` base paths on controllers
> - Check for proper path concatenation

> [!TIP]
> **Missing Methods**
> - Ensure annotations follow Spring conventions
> - Check for typos in annotation names

### Debug Information

Enable framework debugging to see detection and parsing details:
```lua
-- In your Neovim config
vim.g.endpoint_debug = true
```

## Integration Notes

> [!INFO]
> - Works with Spring Boot 2.x and 3.x
> - Compatible with Spring WebMVC and WebFlux
> - Supports both Java and Kotlin codebases
> - Handles nested path structures and path variables
> - Automatically excludes build directories from search
> - Supports reactive endpoints and functional routing
> - Compatible with Spring Security and custom filters