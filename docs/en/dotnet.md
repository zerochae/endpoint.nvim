# ASP.NET Core Framework Support

## Overview

The ASP.NET Core Framework implementation provides comprehensive support for ASP.NET Core applications, including minimal APIs, controller-based APIs, and attribute routing. It detects ASP.NET Core projects and parses various route definition patterns to extract API endpoint information.

## Framework Details

- **Name**: `dotnet`
- **Language**: C#
- **File Extensions**: `*.cs`
- **Framework Class**: `DotNetFramework`

## Detection Strategy

### Dependency-Based Detection

The framework detects ASP.NET Core projects by looking for specific dependencies and project files:

**Required Dependencies:**
- `Microsoft.AspNetCore`
- `Microsoft.AspNetCore.App`
- `Microsoft.AspNetCore.Mvc`

**Manifest Files Searched:**
- `*.csproj`
- `*.fsproj`
- `packages.config`
- `Directory.Build.props`

> [!NOTE]
> ASP.NET Core detection uses dependency-based strategy to search for ASP.NET Core-related dependencies in .NET project files.

## Parsing Strategy

### Annotation-Based Parsing (Attribute and Minimal API Parsing)

The framework uses attribute-based and minimal API parsing to extract endpoint information from ASP.NET Core route definitions.

### Supported Route Patterns

| Pattern Type | HTTP Method | Example |
|--------------|-------------|---------|
| `[HttpGet]` | GET | `[HttpGet("/users")] public IActionResult GetUsers()` |
| `[HttpPost]` | POST | `[HttpPost("/users")] public IActionResult CreateUser()` |
| `[HttpPut]` | PUT | `[HttpPut("/users/{id}")] public IActionResult UpdateUser()` |
| `[HttpDelete]` | DELETE | `[HttpDelete("/users/{id}")] public IActionResult DeleteUser()` |
| `[Route]` | Multiple | `[Route("/users")] public class UsersController` |
| `app.MapGet` | GET | `app.MapGet("/users", () => { ... })` |
| `app.MapPost` | POST | `app.MapPost("/users", () => { ... })` |

### Path Extraction Patterns

The parser recognizes various path definition formats:

1. **Attribute Routes**: `[HttpGet("/users")]`
2. **Single Quotes**: `[HttpGet('/users')]`
3. **Minimal APIs**: `app.MapGet("/users", handler)`
4. **Controller Routes**: `[Route("api/[controller]")]`

### Controller Base Route Support

ASP.NET Core's controller-level routing is fully supported:

```csharp
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    [HttpGet]                    // Final path: /api/users
    public IActionResult GetUsers() { }

    [HttpGet("{id}")]            // Final path: /api/users/{id}
    public IActionResult GetUser(int id) { }

    [HttpPost]                   // Final path: /api/users
    public IActionResult CreateUser() { }
}
```

> [!TIP]
> Controller base routes with `[Route]` attributes are automatically detected and combined with action routes.

## Configuration Options

### File Processing
- **Include Patterns**: `*.cs`
- **Exclude Patterns**:
  - `**/bin` (Build output)
  - `**/obj` (Build cache)
  - `**/packages` (NuGet packages)

### Search Options
- `--type cs`: Optimizes search for C# files

### Pattern Matching
```lua
patterns = {
  GET = { "\\[HttpGet", "app\\.MapGet", "\\[Route.*HttpVerbs\\.Get" },
  POST = { "\\[HttpPost", "app\\.MapPost", "\\[Route.*HttpVerbs\\.Post" },
  PUT = { "\\[HttpPut", "app\\.MapPut", "\\[Route.*HttpVerbs\\.Put" },
  DELETE = { "\\[HttpDelete", "app\\.MapDelete", "\\[Route.*HttpVerbs\\.Delete" },
  PATCH = { "\\[HttpPatch", "app\\.MapPatch", "\\[Route.*HttpVerbs\\.Patch" },
}
```

## Metadata Enhancement

### Framework-Specific Tags
- `csharp` (language)
- `dotnet` (framework)
- `aspnetcore` (framework)

### Metadata Fields
- `framework_version`: "dotnet"
- `language`: "csharp"
- `controller_name`: Controller class name
- `action_name`: Action method name

### Confidence Scoring
Base confidence: 0.8

**Confidence Boosts:**
- +0.1 for well-formed paths (starting with `/`)
- +0.1 for standard HTTP methods

## Example Endpoint Structures

### Controller-Based API
```csharp
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    [HttpGet]
    public IActionResult GetUsers()
    {
        return Ok(new { users = new object[] { } });
    }
    // Detected: GET /api/users

    [HttpGet("{id}")]
    public IActionResult GetUser(int id)
    {
        return Ok(new { user = new { id } });
    }
    // Detected: GET /api/users/{id}

    [HttpPost]
    public IActionResult CreateUser([FromBody] object user)
    {
        return CreatedAtAction(nameof(GetUser), new { id = 1 }, user);
    }
    // Detected: POST /api/users

    [HttpPut("{id}")]
    public IActionResult UpdateUser(int id, [FromBody] object user)
    {
        return Ok(new { id, user });
    }
    // Detected: PUT /api/users/{id}

    [HttpDelete("{id}")]
    public IActionResult DeleteUser(int id)
    {
        return Ok(new { deleted = id });
    }
    // Detected: DELETE /api/users/{id}
}
```

### Minimal APIs (ASP.NET Core 6+)
```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "Hello World!");
// Detected: GET /

app.MapGet("/users", () => new { users = new object[] { } });
// Detected: GET /users

app.MapPost("/users", (object user) => Results.Created($"/users/1", user));
// Detected: POST /users

app.MapGet("/users/{id}", (int id) => new { user = new { id } });
// Detected: GET /users/{id}

app.MapPut("/users/{id}", (int id, object user) => new { id, user });
// Detected: PUT /users/{id}

app.MapDelete("/users/{id}", (int id) => new { deleted = id });
// Detected: DELETE /users/{id}

app.Run();
```

### Advanced Route Patterns
```csharp
[ApiController]
public class ApiController : ControllerBase
{
    [HttpGet("users/{userId}/posts/{postId}")]
    public IActionResult GetUserPost(int userId, int postId)
    {
        return Ok(new { userId, postId });
    }
    // Detected: GET /users/{userId}/posts/{postId}

    [HttpGet("search")]
    public IActionResult Search([FromQuery] string q = "")
    {
        return Ok(new { query = q, results = new object[] { } });
    }
    // Detected: GET /search

    [Route("api/v{version:apiVersion}/users")]
    [HttpGet]
    public IActionResult GetUsersVersioned()
    {
        return Ok(new { users = new object[] { } });
    }
    // Detected: GET /api/v{version:apiVersion}/users
}
```

### Area-Based Organization
```csharp
[Area("Admin")]
[Route("admin/[controller]")]
public class UsersController : ControllerBase
{
    [HttpGet]
    public IActionResult GetUsers()
    {
        return Ok();
    }
    // Detected: GET /admin/users

    [HttpGet("{id}")]
    public IActionResult GetUser(int id)
    {
        return Ok();
    }
    // Detected: GET /admin/users/{id}
}
```

## Troubleshooting

### Common Issues

> [!WARNING]
> **No Endpoints Detected**
> - Verify ASP.NET Core dependencies in `.csproj` file
> - Check that attributes use proper ASP.NET Core syntax
> - Ensure files have `.cs` extensions

> [!CAUTION]
> **Controller Routes Not Combined**
> - Verify controller-level `[Route]` attributes
> - Check that `using Microsoft.AspNetCore.Mvc` is included

> [!TIP]
> **Missing Minimal API Endpoints**
> - Ensure minimal API syntax is correct (`app.MapGet`, etc.)
> - Check that endpoints are defined after `var app = builder.Build()`

### Debug Information

Enable framework debugging to see detection and parsing details:
```lua
-- In your Neovim config
vim.g.endpoint_debug = true
```

## Integration Notes

> [!INFO]
> - Works with ASP.NET Core 3.1+
> - Compatible with both controller-based and minimal APIs
> - Supports attribute routing and conventional routing
> - Handles area-based organization and API versioning
> - Automatically excludes build directories and NuGet packages
> - Supports route constraints and parameter binding
> - Compatible with Swagger/OpenAPI and API documentation tools