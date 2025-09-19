# Symfony Framework Support

## Overview

The Symfony Framework implementation provides comprehensive support for Symfony applications, including annotations, attributes, and controller-based organization. It detects Symfony projects and parses various route definition patterns to extract API endpoint information.

## Framework Details

- **Name**: `symfony`
- **Language**: PHP
- **File Extensions**: `*.php`
- **Framework Class**: `SymfonyFramework`

## Detection Strategy

### Dependency-Based Detection

The framework detects Symfony projects by looking for specific dependencies in PHP package files:

**Required Dependencies:**
- `symfony/framework-bundle`
- `symfony/routing`
- `symfony/symfony`

**Manifest Files Searched:**
- `composer.json`
- `composer.lock`
- `symfony.lock`

> [!NOTE]
> Symfony detection uses dependency-based strategy to search for Symfony-related dependencies in PHP package manifest files.

## Parsing Strategy

### Annotation-Based Parsing (Route Annotation/Attribute Parsing)

The framework uses annotation and attribute-based parsing to extract endpoint information from Symfony route definitions.

### Supported Route Annotations/Attributes

| Annotation/Attribute | HTTP Method | Example |
|---------------------|-------------|---------|
| `@Route` | Multiple/Specified | `@Route("/users", methods={"GET"})` |
| `#[Route]` | Multiple/Specified | `#[Route('/users', methods: ['GET'])]` |
| `@Get` | GET | `@Get("/users")` |
| `@Post` | POST | `@Post("/users")` |
| `@Put` | PUT | `@Put("/users/{id}")` |
| `@Delete` | DELETE | `@Delete("/users/{id}")` |

### Path Extraction Patterns

The parser recognizes various path definition formats:

1. **Simple Path**: `@Route("/users")`
2. **Single Quotes**: `@Route('/users')`
3. **Methods Parameter**: `@Route("/users", methods={"GET", "POST"})`
4. **PHP 8 Attributes**: `#[Route('/users', methods: ['GET'])]`

### Controller Base Route Support

Symfony's controller-level route annotations are fully supported:

```php
<?php

/**
 * @Route("/api/users")
 */
class UserController extends AbstractController
{
    /**
     * @Route("/", methods={"GET"})
     */
    public function index(): Response
    {
        // Final path: /api/users/
    }

    /**
     * @Route("/{id}", methods={"GET"})
     */
    public function show(int $id): Response
    {
        // Final path: /api/users/{id}
    }
}
```

> [!TIP]
> Controller base routes are automatically detected and combined with action routes.

## Configuration Options

### File Processing
- **Include Patterns**: `*.php`
- **Exclude Patterns**:
  - `**/vendor` (Composer packages)
  - `**/var` (Cache and logs)
  - `**/public` (Public assets)

### Search Options
- `--type php`: Optimizes search for PHP files

### Pattern Matching
```lua
patterns = {
  GET = { "@Route.*GET", "#\\[Route.*GET" },
  POST = { "@Route.*POST", "#\\[Route.*POST" },
  PUT = { "@Route.*PUT", "#\\[Route.*PUT" },
  DELETE = { "@Route.*DELETE", "#\\[Route.*DELETE" },
  PATCH = { "@Route.*PATCH", "#\\[Route.*PATCH" },
}
```

## Metadata Enhancement

### Framework-Specific Tags
- `php` (language)
- `symfony` (framework)

### Metadata Fields
- `framework_version`: "symfony"
- `language`: "php"
- `controller_name`: Controller class name
- `action_name`: Action method name

### Confidence Scoring
Base confidence: 0.8

**Confidence Boosts:**
- +0.1 for well-formed paths (starting with `/`)
- +0.1 for standard HTTP methods

## Example Endpoint Structures

### Annotation-Based Routes (Symfony 5.x and earlier)
```php
<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\Routing\Annotation\Route;

/**
 * @Route("/api/users")
 */
class UserController extends AbstractController
{
    /**
     * @Route("/", methods={"GET"})
     */
    public function index(): Response
    {
        return $this->json(['users' => []]);
    }
    // Detected: GET /api/users/

    /**
     * @Route("/{id}", methods={"GET"})
     */
    public function show(int $id): Response
    {
        return $this->json(['user' => ['id' => $id]]);
    }
    // Detected: GET /api/users/{id}

    /**
     * @Route("/", methods={"POST"})
     */
    public function create(): Response
    {
        return $this->json(['created' => true]);
    }
    // Detected: POST /api/users/
}
```

### Attribute-Based Routes (Symfony 6.x+)
```php
<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/users')]
class UserController extends AbstractController
{
    #[Route('/', methods: ['GET'])]
    public function index(): Response
    {
        return $this->json(['users' => []]);
    }
    // Detected: GET /api/users/

    #[Route('/{id}', methods: ['GET'])]
    public function show(int $id): Response
    {
        return $this->json(['user' => ['id' => $id]]);
    }
    // Detected: GET /api/users/{id}

    #[Route('/', methods: ['POST'])]
    public function create(): Response
    {
        return $this->json(['created' => true]);
    }
    // Detected: POST /api/users/
}
```

### Advanced Route Patterns
```php
<?php

/**
 * @Route("/api/v1")
 */
class ApiController extends AbstractController
{
    /**
     * @Route("/users/{userId}/posts/{postId}", methods={"GET"})
     */
    public function getUserPost(int $userId, int $postId): Response
    {
        return $this->json(['userId' => $userId, 'postId' => $postId]);
    }
    // Detected: GET /api/v1/users/{userId}/posts/{postId}

    /**
     * @Route("/search", methods={"GET"})
     */
    public function search(): Response
    {
        return $this->json(['query' => '', 'results' => []]);
    }
    // Detected: GET /api/v1/search
}
```

## Troubleshooting

### Common Issues

> [!WARNING]
> **No Endpoints Detected**
> - Verify Symfony dependencies in `composer.json`
> - Check that annotations/attributes use proper Symfony syntax
> - Ensure files have `.php` extensions

> [!CAUTION]
> **Controller Base Routes Not Combined**
> - Verify controller-level `@Route` or `#[Route]` annotations
> - Check that `use` statements include proper routing classes

> [!TIP]
> **Missing PHP 8 Attributes**
> - Ensure PHP 8+ for attribute support
> - Check that attribute syntax is correct with `#[Route]`

### Debug Information

Enable framework debugging to see detection and parsing details:
```lua
-- In your Neovim config
vim.g.endpoint_debug = true
```

## Integration Notes

> [!INFO]
> - Works with Symfony 4.x, 5.x, and 6.x
> - Compatible with both annotations and PHP 8 attributes
> - Supports controller-level and action-level routes
> - Handles nested route structures and route parameters
> - Automatically excludes vendor packages and cache directories
> - Supports Symfony Flex and traditional Symfony projects
> - Compatible with API Platform and custom routing