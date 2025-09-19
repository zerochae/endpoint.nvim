# Symfony Framework 지원

## 개요

Symfony Framework 구현체는 Symfony 애플리케이션을 포괄적으로 지원하며, 어노테이션, 속성, 컨트롤러 기반 구조를 포함합니다. Symfony 프로젝트를 감지하고 다양한 라우트 정의 패턴을 파싱하여 API 엔드포인트 정보를 추출합니다.

## 프레임워크 세부사항

- **이름**: `symfony`
- **언어**: PHP
- **파일 확장자**: `*.php`
- **프레임워크 클래스**: `SymfonyFramework`

## 감지 전략

### 의존성 기반 감지

프레임워크는 PHP 패키지 파일에서 특정 의존성을 찾아 Symfony 프로젝트를 감지합니다:

**필수 의존성:**
- `symfony/framework-bundle`
- `symfony/routing`
- `symfony/symfony`

**검색 대상 매니페스트 파일:**
- `composer.json`
- `composer.lock`
- `symfony.lock`

> [!NOTE]
> Symfony 감지는 의존성 기반 전략을 사용하여 PHP 패키지 매니페스트 파일에서 Symfony 관련 의존성을 검색합니다.

## 파싱 전략

### 어노테이션 기반 파싱 (라우트 어노테이션/속성 파싱)

프레임워크는 어노테이션 및 속성 기반 파싱을 사용하여 Symfony 라우트 정의에서 엔드포인트 정보를 추출합니다.

### 지원되는 라우트 어노테이션/속성

| 어노테이션/속성 | HTTP 메서드 | 예제 |
|----------------|-------------|------|
| `@Route` | 다중/지정됨 | `@Route("/users", methods={"GET"})` |
| `#[Route]` | 다중/지정됨 | `#[Route('/users', methods: ['GET'])]` |
| `@Get` | GET | `@Get("/users")` |
| `@Post` | POST | `@Post("/users")` |
| `@Put` | PUT | `@Put("/users/{id}")` |
| `@Delete` | DELETE | `@Delete("/users/{id}")` |

### 경로 추출 패턴

파서는 다양한 경로 정의 형식을 인식합니다:

1. **단순 경로**: `@Route("/users")`
2. **단일 따옴표**: `@Route('/users')`
3. **메서드 매개변수**: `@Route("/users", methods={"GET", "POST"})`
4. **PHP 8 속성**: `#[Route('/users', methods: ['GET'])]`

### 컨트롤러 기본 라우트 지원

Symfony의 컨트롤러 레벨 라우트 어노테이션이 완전히 지원됩니다:

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
        // 최종 경로: /api/users/
    }

    /**
     * @Route("/{id}", methods={"GET"})
     */
    public function show(int $id): Response
    {
        // 최종 경로: /api/users/{id}
    }
}
```

> [!TIP]
> 컨트롤러 기본 라우트는 자동으로 감지되어 액션 라우트와 결합됩니다.

## 설정 옵션

### 파일 처리
- **포함 패턴**: `*.php`
- **제외 패턴**:
  - `**/vendor` (Composer 패키지)
  - `**/var` (캐시 및 로그)
  - `**/public` (공개 자산)

### 검색 옵션
- `--type php`: PHP 파일 검색 최적화

### 패턴 매칭
```lua
patterns = {
  GET = { "@Route.*GET", "#\\[Route.*GET" },
  POST = { "@Route.*POST", "#\\[Route.*POST" },
  PUT = { "@Route.*PUT", "#\\[Route.*PUT" },
  DELETE = { "@Route.*DELETE", "#\\[Route.*DELETE" },
  PATCH = { "@Route.*PATCH", "#\\[Route.*PATCH" },
}
```

## 메타데이터 향상

### 프레임워크별 태그
- `php` (언어)
- `symfony` (프레임워크)

### 메타데이터 필드
- `framework_version`: "symfony"
- `language`: "php"
- `controller_name`: 컨트롤러 클래스 이름
- `action_name`: 액션 메서드 이름

### 신뢰도 점수
기본 신뢰도: 0.8

**신뢰도 향상:**
- +0.1 잘 형성된 경로 (`/`로 시작)
- +0.1 표준 HTTP 메서드

## 엔드포인트 구조 예제

### 어노테이션 기반 라우트 (Symfony 5.x 및 이전)
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
    // 감지됨: GET /api/users/

    /**
     * @Route("/{id}", methods={"GET"})
     */
    public function show(int $id): Response
    {
        return $this->json(['user' => ['id' => $id]]);
    }
    // 감지됨: GET /api/users/{id}

    /**
     * @Route("/", methods={"POST"})
     */
    public function create(): Response
    {
        return $this->json(['created' => true]);
    }
    // 감지됨: POST /api/users/
}
```

### 속성 기반 라우트 (Symfony 6.x+)
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
    // 감지됨: GET /api/users/

    #[Route('/{id}', methods: ['GET'])]
    public function show(int $id): Response
    {
        return $this->json(['user' => ['id' => $id]]);
    }
    // 감지됨: GET /api/users/{id}

    #[Route('/', methods: ['POST'])]
    public function create(): Response
    {
        return $this->json(['created' => true]);
    }
    // 감지됨: POST /api/users/
}
```

### 고급 라우트 패턴
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
    // 감지됨: GET /api/v1/users/{userId}/posts/{postId}

    /**
     * @Route("/search", methods={"GET"})
     */
    public function search(): Response
    {
        return $this->json(['query' => '', 'results' => []]);
    }
    // 감지됨: GET /api/v1/search
}
```

## 문제 해결

### 일반적인 문제

> [!WARNING]
> **엔드포인트가 감지되지 않음**
> - `composer.json`에서 Symfony 의존성 확인
> - 어노테이션/속성이 올바른 Symfony 문법을 사용하는지 확인
> - 파일이 `.php` 확장자를 가지는지 확인

> [!CAUTION]
> **컨트롤러 기본 라우트가 결합되지 않음**
> - 컨트롤러 레벨 `@Route` 또는 `#[Route]` 어노테이션 확인
> - `use` 문이 적절한 라우팅 클래스를 포함하는지 확인

> [!TIP]
> **누락된 PHP 8 속성**
> - 속성 지원을 위해 PHP 8+ 확인
> - `#[Route]`로 속성 문법이 올바른지 확인

### 디버그 정보

프레임워크 디버깅을 활성화하여 감지 및 파싱 세부사항을 확인:
```lua
-- Neovim 설정에서
vim.g.endpoint_debug = true
```

## 통합 노트

> [!INFO]
> - Symfony 4.x, 5.x, 6.x 지원
> - 어노테이션 및 PHP 8 속성 모두 호환
> - 컨트롤러 레벨 및 액션 레벨 라우트 지원
> - 중첩된 라우트 구조 및 라우트 매개변수 처리
> - vendor 패키지 및 캐시 디렉토리를 검색에서 자동 제외
> - Symfony Flex 및 전통적인 Symfony 프로젝트 지원
> - API Platform 및 사용자 정의 라우팅과 호환