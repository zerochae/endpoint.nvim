# NestJS Framework Support

## Overview

The NestJS Framework implementation provides comprehensive support for NestJS applications, including decorators and module-based architecture. It detects NestJS projects and parses various decorator patterns to extract API endpoint information.

## Framework Details

- **Name**: `nestjs`
- **Language**: TypeScript, JavaScript
- **File Extensions**: `*.ts`, `*.js`
- **Framework Class**: `NestJsFramework`

## Detection Strategy

### Dependency-Based Detection

The framework detects NestJS projects by looking for specific dependencies in Node.js package files:

**Required Dependencies:**
- `@nestjs/core`
- `@nestjs/common`
- `nestjs`

**Manifest Files Searched:**
- `package.json`
- `package-lock.json`
- `yarn.lock`

> [!NOTE]
> NestJS detection uses dependency-based strategy to search for NestJS-related dependencies in Node.js package manifest files.

## Parsing Strategy

### Annotation-Based Parsing (Decorator Parsing)

The framework uses decorator-based parsing to extract endpoint information from NestJS decorators.

### Supported Decorators

| Decorator | HTTP Method | Example |
|-----------|-------------|---------|
| `@Get` | GET | `@Get('users')` |
| `@Post` | POST | `@Post('users')` |
| `@Put` | PUT | `@Put('users/:id')` |
| `@Delete` | DELETE | `@Delete('users/:id')` |
| `@Patch` | PATCH | `@Patch('users/:id')` |
| `@All` | All Methods | `@All('*')` |

### Path Extraction Patterns

The parser recognizes various path definition formats:

1. **Simple Path**: `@Get('users')`
2. **Single Quotes**: `@Get("users")`
3. **Empty Path**: `@Get()` (inherits from controller path)
4. **Parameter Path**: `@Get(':id')`

### Controller Base Path Support

The framework automatically detects and combines controller-level `@Controller` decorators with method-level decorators:

```typescript
@Controller('api/users')  // Base path
export class UserController {

  @Get()                  // Method path (empty)
  getUsers() {           // Final path: /api/users
    // ...
  }

  @Get(':id')            // Method path
  getUser(@Param('id') id: string) {  // Final path: /api/users/:id
    // ...
  }
}
```

> [!TIP]
> Controller base paths are automatically detected and combined with method paths.

## Configuration Options

### File Processing
- **Include Patterns**: `*.ts`, `*.js`
- **Exclude Patterns**:
  - `**/node_modules` (Node.js packages)
  - `**/dist` (Build output)
  - `**/build` (Build output)
  - `**/.next` (Next.js build)

### Search Options
- `--type ts`: Optimizes search for TypeScript files
- `--type js`: Optimizes search for JavaScript files

### Pattern Matching
```lua
patterns = {
  GET = { "@Get\\s*\\(", "@All\\s*\\(" },
  POST = { "@Post\\s*\\(", "@All\\s*\\(" },
  PUT = { "@Put\\s*\\(", "@All\\s*\\(" },
  DELETE = { "@Delete\\s*\\(", "@All\\s*\\(" },
  PATCH = { "@Patch\\s*\\(", "@All\\s*\\(" },
}
```

## Metadata Enhancement

### Framework-Specific Tags
- `typescript` or `javascript` (language)
- `nestjs` (framework)

### Metadata Fields
- `framework_version`: "nestjs"
- `language`: "typescript" or "javascript"
- `controller_base_path`: Base path from `@Controller`
- `controller_name`: Controller class name

### Confidence Scoring
Base confidence: 0.8

**Confidence Boosts:**
- +0.1 for well-formed paths
- +0.1 for standard HTTP methods

## Example Endpoint Structures

### Basic NestJS Controller
```typescript
import { Controller, Get, Post, Put, Delete, Param, Body } from '@nestjs/common';

@Controller('api/users')
export class UserController {

  @Get()
  getAllUsers() {
    return { users: [] };
  }
  // Detected: GET /api/users

  @Get(':id')
  getUser(@Param('id') id: string) {
    return { user: { id } };
  }
  // Detected: GET /api/users/:id

  @Post()
  createUser(@Body() user: any) {
    return user;
  }
  // Detected: POST /api/users

  @Put(':id')
  updateUser(@Param('id') id: string, @Body() user: any) {
    return { id, ...user };
  }
  // Detected: PUT /api/users/:id

  @Delete(':id')
  deleteUser(@Param('id') id: string) {
    return { deleted: id };
  }
  // Detected: DELETE /api/users/:id
}
```

### Module-Based Organization
```typescript
// users.controller.ts
@Controller('users')
export class UsersController {

  @Get()
  findAll() {
    return { users: [] };
  }
  // Detected: GET /users

  @Get(':id')
  findOne(@Param('id') id: string) {
    return { user: { id } };
  }
  // Detected: GET /users/:id
}

// posts.controller.ts
@Controller('posts')
export class PostsController {

  @Get()
  findAll() {
    return { posts: [] };
  }
  // Detected: GET /posts

  @Post()
  create(@Body() post: any) {
    return post;
  }
  // Detected: POST /posts
}
```

### Advanced Decorator Patterns
```typescript
@Controller('api/v1/users')
export class UserV1Controller {

  @Get(':userId/posts/:postId')
  getUserPost(
    @Param('userId') userId: string,
    @Param('postId') postId: string
  ) {
    return { userId, postId };
  }
  // Detected: GET /api/v1/users/:userId/posts/:postId

  @Get('search')
  searchUsers(@Query('q') query: string) {
    return { query, results: [] };
  }
  // Detected: GET /api/v1/users/search

  @All('*')
  catchAll() {
    return { message: 'Catch all route' };
  }
  // Detected: ALL /api/v1/users/*
}
```

## Troubleshooting

### Common Issues

> [!WARNING]
> **No Endpoints Detected**
> - Verify NestJS dependencies in `package.json`
> - Check that decorators use proper NestJS syntax
> - Ensure files have `.ts` or `.js` extensions

> [!CAUTION]
> **Controller Paths Not Combined**
> - Verify `@Controller` decorator has proper path
> - Check that decorators are properly imported from `@nestjs/common`

> [!TIP]
> **Missing TypeScript Decorators**
> - Ensure `experimentalDecorators` is enabled in `tsconfig.json`
> - Check that decorator syntax is correct

### Debug Information

Enable framework debugging to see detection and parsing details:
```lua
-- In your Neovim config
vim.g.endpoint_debug = true
```

## Integration Notes

> [!INFO]
> - Works with NestJS 8.x, 9.x, and 10.x
> - Compatible with both TypeScript and JavaScript codebases
> - Supports module-based architecture
> - Handles nested route structures and route parameters
> - Automatically excludes Node.js modules and build directories
> - Supports guards, interceptors, and pipes (decorators only)
> - Compatible with microservices and GraphQL modules