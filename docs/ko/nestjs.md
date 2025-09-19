# NestJS Framework 지원

## 개요

NestJS Framework 구현체는 NestJS 애플리케이션을 포괄적으로 지원하며, 데코레이터와 모듈 기반 아키텍처를 포함합니다. NestJS 프로젝트를 감지하고 다양한 데코레이터 패턴을 파싱하여 API 엔드포인트 정보를 추출합니다.

## 프레임워크 세부사항

- **이름**: `nestjs`
- **언어**: TypeScript, JavaScript
- **파일 확장자**: `*.ts`, `*.js`
- **프레임워크 클래스**: `NestJsFramework`

## 감지 전략

### 의존성 기반 감지

프레임워크는 Node.js 패키지 파일에서 특정 의존성을 찾아 NestJS 프로젝트를 감지합니다:

**필수 의존성:**
- `@nestjs/core`
- `@nestjs/common`
- `nestjs`

**검색 대상 매니페스트 파일:**
- `package.json`
- `package-lock.json`
- `yarn.lock`

> [!NOTE]
> NestJS 감지는 의존성 기반 전략을 사용하여 Node.js 패키지 매니페스트 파일에서 NestJS 관련 의존성을 검색합니다.

## 파싱 전략

### 어노테이션 기반 파싱 (데코레이터 파싱)

프레임워크는 데코레이터 기반 파싱을 사용하여 NestJS 데코레이터에서 엔드포인트 정보를 추출합니다.

### 지원되는 데코레이터

| 데코레이터 | HTTP 메서드 | 예제 |
|-----------|-------------|------|
| `@Get` | GET | `@Get('users')` |
| `@Post` | POST | `@Post('users')` |
| `@Put` | PUT | `@Put('users/:id')` |
| `@Delete` | DELETE | `@Delete('users/:id')` |
| `@Patch` | PATCH | `@Patch('users/:id')` |
| `@All` | 모든 메서드 | `@All('*')` |

### 경로 추출 패턴

파서는 다양한 경로 정의 형식을 인식합니다:

1. **단순 경로**: `@Get('users')`
2. **단일 따옴표**: `@Get("users")`
3. **빈 경로**: `@Get()` (컨트롤러 경로에서 상속)
4. **매개변수 경로**: `@Get(':id')`

### 컨트롤러 기본 경로 지원

프레임워크는 컨트롤러 레벨의 `@Controller` 데코레이터를 자동으로 감지하여 메서드 레벨 데코레이터와 결합합니다:

```typescript
@Controller('api/users')  // 기본 경로
export class UserController {

  @Get()                  // 메서드 경로 (빈 값)
  getUsers() {           // 최종 경로: /api/users
    // ...
  }

  @Get(':id')            // 메서드 경로
  getUser(@Param('id') id: string) {  // 최종 경로: /api/users/:id
    // ...
  }
}
```

> [!TIP]
> 컨트롤러 기본 경로는 자동으로 감지되어 메서드 경로와 결합됩니다.

## 설정 옵션

### 파일 처리
- **포함 패턴**: `*.ts`, `*.js`
- **제외 패턴**:
  - `**/node_modules` (Node.js 패키지)
  - `**/dist` (빌드 출력)
  - `**/build` (빌드 출력)
  - `**/.next` (Next.js 빌드)

### 검색 옵션
- `--type ts`: TypeScript 파일 검색 최적화
- `--type js`: JavaScript 파일 검색 최적화

### 패턴 매칭
```lua
patterns = {
  GET = { "@Get\\s*\\(", "@All\\s*\\(" },
  POST = { "@Post\\s*\\(", "@All\\s*\\(" },
  PUT = { "@Put\\s*\\(", "@All\\s*\\(" },
  DELETE = { "@Delete\\s*\\(", "@All\\s*\\(" },
  PATCH = { "@Patch\\s*\\(", "@All\\s*\\(" },
}
```

## 메타데이터 향상

### 프레임워크별 태그
- `typescript` 또는 `javascript` (언어)
- `nestjs` (프레임워크)

### 메타데이터 필드
- `framework_version`: "nestjs"
- `language`: "typescript" 또는 "javascript"
- `controller_base_path`: `@Controller`의 기본 경로
- `controller_name`: 컨트롤러 클래스 이름

### 신뢰도 점수
기본 신뢰도: 0.8

**신뢰도 향상:**
- +0.1 잘 형성된 경로
- +0.1 표준 HTTP 메서드

## 엔드포인트 구조 예제

### 기본 NestJS 컨트롤러
```typescript
import { Controller, Get, Post, Put, Delete, Param, Body } from '@nestjs/common';

@Controller('api/users')
export class UserController {

  @Get()
  getAllUsers() {
    return { users: [] };
  }
  // 감지됨: GET /api/users

  @Get(':id')
  getUser(@Param('id') id: string) {
    return { user: { id } };
  }
  // 감지됨: GET /api/users/:id

  @Post()
  createUser(@Body() user: any) {
    return user;
  }
  // 감지됨: POST /api/users

  @Put(':id')
  updateUser(@Param('id') id: string, @Body() user: any) {
    return { id, ...user };
  }
  // 감지됨: PUT /api/users/:id

  @Delete(':id')
  deleteUser(@Param('id') id: string) {
    return { deleted: id };
  }
  // 감지됨: DELETE /api/users/:id
}
```

### 모듈 기반 구조
```typescript
// users.controller.ts
@Controller('users')
export class UsersController {

  @Get()
  findAll() {
    return { users: [] };
  }
  // 감지됨: GET /users

  @Get(':id')
  findOne(@Param('id') id: string) {
    return { user: { id } };
  }
  // 감지됨: GET /users/:id
}

// posts.controller.ts
@Controller('posts')
export class PostsController {

  @Get()
  findAll() {
    return { posts: [] };
  }
  // 감지됨: GET /posts

  @Post()
  create(@Body() post: any) {
    return post;
  }
  // 감지됨: POST /posts
}
```

### 고급 데코레이터 패턴
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
  // 감지됨: GET /api/v1/users/:userId/posts/:postId

  @Get('search')
  searchUsers(@Query('q') query: string) {
    return { query, results: [] };
  }
  // 감지됨: GET /api/v1/users/search

  @All('*')
  catchAll() {
    return { message: 'Catch all route' };
  }
  // 감지됨: ALL /api/v1/users/*
}
```

## 문제 해결

### 일반적인 문제

> [!WARNING]
> **엔드포인트가 감지되지 않음**
> - `package.json`에서 NestJS 의존성 확인
> - 데코레이터가 올바른 NestJS 문법을 사용하는지 확인
> - 파일이 `.ts` 또는 `.js` 확장자를 가지는지 확인

> [!CAUTION]
> **컨트롤러 경로가 결합되지 않음**
> - `@Controller` 데코레이터가 올바른 경로를 가지는지 확인
> - 데코레이터가 `@nestjs/common`에서 올바르게 import되었는지 확인

> [!TIP]
> **누락된 TypeScript 데코레이터**
> - `tsconfig.json`에서 `experimentalDecorators`가 활성화되었는지 확인
> - 데코레이터 문법이 올바른지 확인

### 디버그 정보

프레임워크 디버깅을 활성화하여 감지 및 파싱 세부사항을 확인:
```lua
-- Neovim 설정에서
vim.g.endpoint_debug = true
```

## 통합 노트

> [!INFO]
> - NestJS 8.x, 9.x, 10.x 지원
> - TypeScript 및 JavaScript 코드베이스 모두 호환
> - 모듈 기반 아키텍처 지원
> - 중첩된 라우트 구조 및 라우트 매개변수 처리
> - Node.js 모듈 및 빌드 디렉토리를 검색에서 자동 제외
> - 가드, 인터셉터, 파이프 지원 (데코레이터만)
> - 마이크로서비스 및 GraphQL 모듈과 호환