# Express Framework Support

## Overview

The Express Framework implementation provides comprehensive support for Express.js applications, including middleware and router-based organization. It detects Express projects and parses various route definition patterns to extract API endpoint information.

## Framework Details

- **Name**: `express`
- **Language**: JavaScript, TypeScript
- **File Extensions**: `*.js`, `*.ts`
- **Framework Class**: `ExpressFramework`

## Detection Strategy

### Dependency-Based Detection

The framework detects Express projects by looking for specific dependencies in Node.js package files:

**Required Dependencies:**
- `express`
- `Express`

**Manifest Files Searched:**
- `package.json`
- `package-lock.json`
- `yarn.lock`

> [!NOTE]
> Express detection uses dependency-based strategy to search for Express-related dependencies in Node.js package manifest files.

## Parsing Strategy

### Annotation-Based Parsing (Route Parsing)

The framework uses route-based parsing to extract endpoint information from Express route definitions.

### Supported Route Methods

| Method | HTTP Method | Example |
|--------|-------------|---------|
| `app.get` | GET | `app.get('/users', handler)` |
| `app.post` | POST | `app.post('/users', handler)` |
| `app.put` | PUT | `app.put('/users/:id', handler)` |
| `app.delete` | DELETE | `app.delete('/users/:id', handler)` |
| `app.patch` | PATCH | `app.patch('/users/:id', handler)` |
| `router.get` | GET | `router.get('/items', handler)` |
| `router.post` | POST | `router.post('/items', handler)` |

### Path Extraction Patterns

The parser recognizes various path definition formats:

1. **Simple Path**: `app.get('/users', handler)`
2. **Single Quotes**: `app.get("/users", handler)`
3. **Template Literals**: `app.get(`/users/${prefix}/items`, handler)`
4. **Router Paths**: `router.get('/items', handler)`

### Router Support

Express's router-based organization is fully supported:

```javascript
const express = require('express');
const router = express.Router();

// Router with mount path
app.use('/api/users', router);

router.get('/', (req, res) => {});       // Final path: /api/users/
router.get('/:id', (req, res) => {});    // Final path: /api/users/:id
```

> [!TIP]
> Router mount paths are automatically detected and combined with route paths.

## Configuration Options

### File Processing
- **Include Patterns**: `*.js`, `*.ts`
- **Exclude Patterns**:
  - `**/node_modules` (Node.js packages)
  - `**/dist` (Build output)
  - `**/build` (Build output)
  - `**/.next` (Next.js build)

### Search Options
- `--type js`: Optimizes search for JavaScript files
- `--type ts`: Optimizes search for TypeScript files

### Pattern Matching
```lua
patterns = {
  GET = { "app\\.get", "router\\.get" },
  POST = { "app\\.post", "router\\.post" },
  PUT = { "app\\.put", "router\\.put" },
  DELETE = { "app\\.delete", "router\\.delete" },
  PATCH = { "app\\.patch", "router\\.patch" },
}
```

## Metadata Enhancement

### Framework-Specific Tags
- `javascript` or `typescript` (language)
- `express` (framework)

### Metadata Fields
- `framework_version`: "express"
- `language`: "javascript" or "typescript"

### Confidence Scoring
Base confidence: 0.8

**Confidence Boosts:**
- +0.1 for well-formed paths (starting with `/`)
- +0.1 for standard HTTP methods

## Example Endpoint Structures

### Basic Express Application
```javascript
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello World');
});
// Detected: GET /

app.get('/users', (req, res) => {
  res.json({ users: [] });
});
// Detected: GET /users

app.post('/users', (req, res) => {
  res.json(req.body);
});
// Detected: POST /users

app.get('/users/:id', (req, res) => {
  res.json({ user: { id: req.params.id } });
});
// Detected: GET /users/:id

app.put('/users/:id', (req, res) => {
  res.json({ id: req.params.id, ...req.body });
});
// Detected: PUT /users/:id

app.delete('/users/:id', (req, res) => {
  res.json({ deleted: req.params.id });
});
// Detected: DELETE /users/:id
```

### Router-Based Organization
```javascript
const express = require('express');
const router = express.Router();

// User router
const userRouter = express.Router();
app.use('/api/users', userRouter);

userRouter.get('/', (req, res) => {
  res.json({ users: [] });
});
// Detected: GET /

userRouter.get('/:id', (req, res) => {
  res.json({ user: { id: req.params.id } });
});
// Detected: GET /:id

// Item router
const itemRouter = express.Router();
app.use('/api/items', itemRouter);

itemRouter.get('/', (req, res) => {
  res.json({ items: [] });
});
// Detected: GET /

itemRouter.post('/', (req, res) => {
  res.json(req.body);
});
// Detected: POST /
```

### Advanced Path Patterns
```javascript
app.get('/users/:userId/posts/:postId', (req, res) => {
  res.json({
    userId: req.params.userId,
    postId: req.params.postId
  });
});
// Detected: GET /users/:userId/posts/:postId

app.get('/search', (req, res) => {
  res.json({ query: req.query.q, results: [] });
});
// Detected: GET /search
```

## Troubleshooting

### Common Issues

> [!WARNING]
> **No Endpoints Detected**
> - Verify Express dependency in `package.json`
> - Check that routes use proper Express syntax
> - Ensure files have `.js` or `.ts` extensions

> [!CAUTION]
> **Router Paths Not Combined**
> - Verify router mount paths with `app.use()`
> - Check that `express.Router()` is properly imported

> [!TIP]
> **Missing Middleware Routes**
> - Only route definitions are detected, not middleware
> - Ensure routes use standard HTTP method names

### Debug Information

Enable framework debugging to see detection and parsing details:
```lua
-- In your Neovim config
vim.g.endpoint_debug = true
```

## Integration Notes

> [!INFO]
> - Works with Express 4.x and 5.x
> - Compatible with both CommonJS and ES modules
> - Supports both JavaScript and TypeScript codebases
> - Handles nested route structures and route parameters
> - Automatically excludes Node.js modules and build directories
> - Supports template literal path definitions
> - Compatible with middleware and route-specific middleware