# Gin Framework 지원

## 개요

Gin Framework 구현체는 Gin 애플리케이션을 포괄적으로 지원하며, 미들웨어와 라우터 그룹 기반 구조를 포함합니다. Gin 프로젝트를 감지하고 다양한 라우트 정의 패턴을 파싱하여 API 엔드포인트 정보를 추출합니다.

## 프레임워크 세부사항

- **이름**: `gin`
- **언어**: Go
- **파일 확장자**: `*.go`
- **프레임워크 클래스**: `GinFramework`

## 감지 전략

### 의존성 기반 감지

프레임워크는 Go 모듈 파일에서 특정 의존성을 찾아 Gin 프로젝트를 감지합니다:

**필수 의존성:**
- `github.com/gin-gonic/gin`
- `gin-gonic/gin`

**검색 대상 매니페스트 파일:**
- `go.mod`
- `go.sum`
- `Gopkg.toml`
- `vendor.json`

> [!NOTE]
> Gin 감지는 의존성 기반 전략을 사용하여 Go 모듈 매니페스트 파일에서 Gin 관련 의존성을 검색합니다.

## 파싱 전략

### 어노테이션 기반 파싱 (라우트 메서드 파싱)

프레임워크는 라우트 메서드 기반 파싱을 사용하여 Gin 라우트 정의에서 엔드포인트 정보를 추출합니다.

### 지원되는 라우트 메서드

| 메서드 | HTTP 메서드 | 예제 |
|--------|-------------|------|
| `router.GET` | GET | `router.GET("/users", handler)` |
| `router.POST` | POST | `router.POST("/users", handler)` |
| `router.PUT` | PUT | `router.PUT("/users/:id", handler)` |
| `router.DELETE` | DELETE | `router.DELETE("/users/:id", handler)` |
| `router.PATCH` | PATCH | `router.PATCH("/users/:id", handler)` |
| `router.Any` | 다중 | `router.Any("/users", handler)` |
| `group.GET` | GET | `group.GET("/profile", handler)` |

### 경로 추출 패턴

파서는 다양한 경로 정의 형식을 인식합니다:

1. **단순 경로**: `router.GET("/users", handler)`
2. **백틱**: `router.GET(`/users`, handler)`
3. **라우터 그룹**: `v1.GET("/users", handler)`
4. **매개변수 경로**: `router.GET("/users/:id", handler)`

### 라우터 그룹 지원

Gin의 라우터 그룹 구조가 완전히 지원됩니다:

```go
package main

import "github.com/gin-gonic/gin"

func main() {
    r := gin.Default()
    
    v1 := r.Group("/api/v1")
    {
        v1.GET("/users", getUsers)     // 최종 경로: /api/v1/users
        v1.POST("/users", createUser)  // 최종 경로: /api/v1/users
    }
}
```

> [!TIP]
> 라우터 그룹 프리픽스는 자동으로 감지되어 라우트 경로와 결합됩니다.

## 설정 옵션

### 파일 처리
- **포함 패턴**: `*.go`
- **제외 패턴**:
  - `**/vendor` (Vendor 의존성)
  - `**/build` (빌드 출력)
  - `**/.git` (Git 저장소)

### 검색 옵션
- `--type go`: Go 파일 검색 최적화

### 패턴 매칭
```lua
patterns = {
  GET = { "router\\.GET", "[a-zA-Z_][a-zA-Z0-9_]*\\.GET" },
  POST = { "router\\.POST", "[a-zA-Z_][a-zA-Z0-9_]*\\.POST" },
  PUT = { "router\\.PUT", "[a-zA-Z_][a-zA-Z0-9_]*\\.PUT" },
  DELETE = { "router\\.DELETE", "[a-zA-Z_][a-zA-Z0-9_]*\\.DELETE" },
  PATCH = { "router\\.PATCH", "[a-zA-Z_][a-zA-Z0-9_]*\\.PATCH" },
}
```

## 메타데이터 향상

### 프레임워크별 태그
- `go` (언어)
- `gin` (프레임워크)

### 메타데이터 필드
- `framework_version`: "gin"
- `language`: "go"

### 신뢰도 점수
기본 신뢰도: 0.8

**신뢰도 향상:**
- +0.1 잘 형성된 경로 (`/`로 시작)
- +0.1 표준 HTTP 메서드

## 엔드포인트 구조 예제

### 기본 Gin 애플리케이션
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
    // 감지됨: GET /
    
    r.GET("/users", getUsers)
    // 감지됨: GET /users
    
    r.POST("/users", createUser)
    // 감지됨: POST /users
    
    r.GET("/users/:id", getUser)
    // 감지됨: GET /users/:id
    
    r.PUT("/users/:id", updateUser)
    // 감지됨: PUT /users/:id
    
    r.DELETE("/users/:id", deleteUser)
    // 감지됨: DELETE /users/:id
    
    r.Run(":8080")
}
```

### 라우터 그룹 구조
```go
func main() {
    r := gin.Default()
    
    // API v1 그룹
    v1 := r.Group("/api/v1")
    {
        users := v1.Group("/users")
        {
            users.GET("/", listUsers)
            // 감지됨: GET /
            
            users.GET("/:id", getUser)
            // 감지됨: GET /:id
            
            users.POST("/", createUser)
            // 감지됨: POST /
        }
        
        posts := v1.Group("/posts")
        {
            posts.GET("/", listPosts)
            // 감지됨: GET /
            
            posts.POST("/", createPost)
            // 감지됨: POST /
        }
    }
}
```

## 문제 해결

### 일반적인 문제

> [!WARNING]
> **엔드포인트가 감지되지 않음**
> - `go.mod`에서 Gin 의존성 확인
> - 라우트가 올바른 Gin 문법을 사용하는지 확인
> - 파일이 `.go` 확장자를 가지는지 확인

> [!CAUTION]
> **라우터 그룹 경로가 결합되지 않음**
> - `r.Group()`으로 라우터 그룹 생성 확인
> - 그룹 변수가 올바르게 사용되는지 확인

> [!TIP]
> **누락된 핸들러 함수**
> - 인라인 및 별도 핸들러 함수 모두 지원됨
> - 라우트 정의가 올바른 형식인지 확인

### 디버그 정보

프레임워크 디버깅을 활성화하여 감지 및 파싱 세부사항을 확인:
```lua
-- Neovim 설정에서
vim.g.endpoint_debug = true
```

## 통합 노트

> [!INFO]
> - Gin v1.x 지원
> - Go 모듈 및 vendor 디렉토리와 호환
> - 라우터 그룹 및 미들웨어 지원
> - 중첩된 라우트 구조 및 라우트 매개변수 처리
> - vendor 의존성 및 빌드 디렉토리를 검색에서 자동 제외
> - 인라인 및 별도 핸들러 함수 지원
> - Gin 미들웨어 및 사용자 정의 미들웨어와 호환