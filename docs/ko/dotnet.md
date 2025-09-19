# ASP.NET Core Framework 지원

## 개요

ASP.NET Core Framework 구현체는 ASP.NET Core 애플리케이션을 포괄적으로 지원하며, 미니멀 API, 컨트롤러 기반 API, 속성 라우팅을 포함합니다. ASP.NET Core 프로젝트를 감지하고 다양한 라우트 정의 패턴을 파싱하여 API 엔드포인트 정보를 추출합니다.

## 프레임워크 세부사항

- **이름**: `dotnet`
- **언어**: C#
- **파일 확장자**: `*.cs`
- **프레임워크 클래스**: `DotNetFramework`

## 감지 전략

### 의존성 기반 감지

프레임워크는 특정 의존성과 프로젝트 파일을 찾아 ASP.NET Core 프로젝트를 감지합니다:

**필수 의존성:**
- `Microsoft.AspNetCore`
- `Microsoft.AspNetCore.App`
- `Microsoft.AspNetCore.Mvc`

**검색 대상 매니페스트 파일:**
- `*.csproj`
- `*.fsproj`
- `packages.config`
- `Directory.Build.props`

> [!NOTE]
> ASP.NET Core 감지는 의존성 기반 전략을 사용하여 .NET 프로젝트 파일에서 ASP.NET Core 관련 의존성을 검색합니다.

## 파싱 전략

### 어노테이션 기반 파싱 (속성 및 미니멀 API 파싱)

프레임워크는 속성 기반 및 미니멀 API 파싱을 사용하여 ASP.NET Core 라우트 정의에서 엔드포인트 정보를 추출합니다.

### 지원되는 라우트 패턴

| 패턴 타입 | HTTP 메서드 | 예제 |
|----------|-------------|------|
| `[HttpGet]` | GET | `[HttpGet("/users")] public IActionResult GetUsers()` |
| `[HttpPost]` | POST | `[HttpPost("/users")] public IActionResult CreateUser()` |
| `[HttpPut]` | PUT | `[HttpPut("/users/{id}")] public IActionResult UpdateUser()` |
| `[HttpDelete]` | DELETE | `[HttpDelete("/users/{id}")] public IActionResult DeleteUser()` |
| `[Route]` | 다중 | `[Route("/users")] public class UsersController` |
| `app.MapGet` | GET | `app.MapGet("/users", () => { ... })` |
| `app.MapPost` | POST | `app.MapPost("/users", () => { ... })` |

### 경로 추출 패턴

파서는 다양한 경로 정의 형식을 인식합니다:

1. **속성 라우트**: `[HttpGet("/users")]`
2. **단일 따옴표**: `[HttpGet('/users')]`
3. **미니멀 API**: `app.MapGet("/users", handler)`
4. **컨트롤러 라우트**: `[Route("api/[controller]")]`

### 컨트롤러 기본 라우트 지원

ASP.NET Core의 컨트롤러 레벨 라우팅이 완전히 지원됩니다:

```csharp
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    [HttpGet]                    // 최종 경로: /api/users
    public IActionResult GetUsers() { }

    [HttpGet("{id}")]            // 최종 경로: /api/users/{id}
    public IActionResult GetUser(int id) { }

    [HttpPost]                   // 최종 경로: /api/users
    public IActionResult CreateUser() { }
}
```

> [!TIP]
> `[Route]` 속성을 가진 컨트롤러 기본 라우트는 자동으로 감지되어 액션 라우트와 결합됩니다.

## 설정 옵션

### 파일 처리
- **포함 패턴**: `*.cs`
- **제외 패턴**:
  - `**/bin` (빌드 출력)
  - `**/obj` (빌드 캐시)
  - `**/packages` (NuGet 패키지)

### 검색 옵션
- `--type cs`: C# 파일 검색 최적화

### 패턴 매칭
```lua
patterns = {
  GET = { "\\[HttpGet", "app\\.MapGet", "\\[Route.*HttpVerbs\\.Get" },
  POST = { "\\[HttpPost", "app\\.MapPost", "\\[Route.*HttpVerbs\\.Post" },
  PUT = { "\\[HttpPut", "app\\.MapPut", "\\[Route.*HttpVerbs\\.Put" },
  DELETE = { "\\[HttpDelete", "app\\.MapDelete", "\\[Route.*HttpVerbs\\.Delete" },
  PATCH = { "\\[HttpPatch", "app\\.MapPatch", "\\[Route.*HttpVerbs\\.Patch" },
}
```

## 메타데이터 향상

### 프레임워크별 태그
- `csharp` (언어)
- `dotnet` (프레임워크)
- `aspnetcore` (프레임워크)

### 메타데이터 필드
- `framework_version`: "dotnet"
- `language`: "csharp"
- `controller_name`: 컨트롤러 클래스 이름
- `action_name`: 액션 메서드 이름

### 신뢰도 점수
기본 신뢰도: 0.8

**신뢰도 향상:**
- +0.1 잘 형성된 경로 (`/`로 시작)
- +0.1 표준 HTTP 메서드

## 엔드포인트 구조 예제

### 컨트롤러 기반 API
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
    // 감지됨: GET /api/users

    [HttpGet("{id}")]
    public IActionResult GetUser(int id)
    {
        return Ok(new { user = new { id } });
    }
    // 감지됨: GET /api/users/{id}

    [HttpPost]
    public IActionResult CreateUser([FromBody] object user)
    {
        return CreatedAtAction(nameof(GetUser), new { id = 1 }, user);
    }
    // 감지됨: POST /api/users

    [HttpPut("{id}")]
    public IActionResult UpdateUser(int id, [FromBody] object user)
    {
        return Ok(new { id, user });
    }
    // 감지됨: PUT /api/users/{id}

    [HttpDelete("{id}")]
    public IActionResult DeleteUser(int id)
    {
        return Ok(new { deleted = id });
    }
    // 감지됨: DELETE /api/users/{id}
}
```

### 미니멀 API (ASP.NET Core 6+)
```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "Hello World!");
// 감지됨: GET /

app.MapGet("/users", () => new { users = new object[] { } });
// 감지됨: GET /users

app.MapPost("/users", (object user) => Results.Created($"/users/1", user));
// 감지됨: POST /users

app.MapGet("/users/{id}", (int id) => new { user = new { id } });
// 감지됨: GET /users/{id}

app.MapPut("/users/{id}", (int id, object user) => new { id, user });
// 감지됨: PUT /users/{id}

app.MapDelete("/users/{id}", (int id) => new { deleted = id });
// 감지됨: DELETE /users/{id}

app.Run();
```

### 고급 라우트 패턴
```csharp
[ApiController]
public class ApiController : ControllerBase
{
    [HttpGet("users/{userId}/posts/{postId}")]
    public IActionResult GetUserPost(int userId, int postId)
    {
        return Ok(new { userId, postId });
    }
    // 감지됨: GET /users/{userId}/posts/{postId}

    [HttpGet("search")]
    public IActionResult Search([FromQuery] string q = "")
    {
        return Ok(new { query = q, results = new object[] { } });
    }
    // 감지됨: GET /search

    [Route("api/v{version:apiVersion}/users")]
    [HttpGet]
    public IActionResult GetUsersVersioned()
    {
        return Ok(new { users = new object[] { } });
    }
    // 감지됨: GET /api/v{version:apiVersion}/users
}
```

### 영역 기반 구조
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
    // 감지됨: GET /admin/users

    [HttpGet("{id}")]
    public IActionResult GetUser(int id)
    {
        return Ok();
    }
    // 감지됨: GET /admin/users/{id}
}
```

## 문제 해결

### 일반적인 문제

> [!WARNING]
> **엔드포인트가 감지되지 않음**
> - `.csproj` 파일에서 ASP.NET Core 의존성 확인
> - 속성이 올바른 ASP.NET Core 문법을 사용하는지 확인
> - 파일이 `.cs` 확장자를 가지는지 확인

> [!CAUTION]
> **컨트롤러 라우트가 결합되지 않음**
> - 컨트롤러 레벨 `[Route]` 속성 확인
> - `using Microsoft.AspNetCore.Mvc`가 포함되었는지 확인

> [!TIP]
> **누락된 미니멀 API 엔드포인트**
> - 미니멀 API 문법이 올바른지 확인 (`app.MapGet` 등)
> - 엔드포인트가 `var app = builder.Build()` 이후에 정의되었는지 확인

### 디버그 정보

프레임워크 디버깅을 활성화하여 감지 및 파싱 세부사항을 확인:
```lua
-- Neovim 설정에서
vim.g.endpoint_debug = true
```

## 통합 노트

> [!INFO]
> - ASP.NET Core 3.1+ 지원
> - 컨트롤러 기반 및 미니멀 API 모두 호환
> - 속성 라우팅 및 관례적 라우팅 지원
> - 영역 기반 구조 및 API 버전 관리 처리
> - 빌드 디렉토리 및 NuGet 패키지를 검색에서 자동 제외
> - 라우트 제약 조건 및 매개변수 바인딩 지원
> - Swagger/OpenAPI 및 API 문서화 도구와 호환