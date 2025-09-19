# Axum Framework 지원

## 개요

Axum Framework 구현체는 Axum 애플리케이션을 포괄적으로 지원하며, 핸들러와 라우터 기반 구조를 포함합니다. Axum 프로젝트를 감지하고 다양한 라우트 정의 패턴을 파싱하여 API 엔드포인트 정보를 추출합니다.

## 프레임워크 세부사항

- **이름**: `axum`
- **언어**: Rust
- **파일 확장자**: `*.rs`
- **프레임워크 클래스**: `AxumFramework`

## 감지 전략

### 의존성 기반 감지

프레임워크는 Rust 패키지 파일에서 특정 의존성을 찾아 Axum 프로젝트를 감지합니다:

**필수 의존성:**
- `axum`
- `axum-core`

**검색 대상 매니페스트 파일:**
- `Cargo.toml`
- `Cargo.lock`

> [!NOTE]
> Axum 감지는 의존성 기반 전략을 사용하여 Rust 패키지 매니페스트 파일에서 Axum 관련 의존성을 검색합니다.

## 파싱 전략

### 어노테이션 기반 파싱 (라우트 메서드 파싱)

프레임워크는 라우트 메서드 기반 파싱을 사용하여 Axum 라우트 정의에서 엔드포인트 정보를 추출합니다.

### 지원되는 라우트 메서드

| 메서드 | HTTP 메서드 | 예제 |
|--------|-------------|------|
| `get` | GET | `get("/users", handler)` |
| `post` | POST | `post("/users", handler)` |
| `put` | PUT | `put("/users/:id", handler)` |
| `delete` | DELETE | `delete("/users/:id", handler)` |
| `patch` | PATCH | `patch("/users/:id", handler)` |
| `any` | 다중 | `any("/users", handler)` |

### 경로 추출 패턴

파서는 다양한 경로 정의 형식을 인식합니다:

1. **단순 경로**: `get("/users", handler)`
2. **단일 따옴표**: `get('/users', handler)`
3. **라우터 중첩**: `Router::new().route("/users", get(handler))`
4. **매개변수 경로**: `get("/users/:id", handler)`

### 라우터 중첩 지원

Axum의 라우터 중첩이 완전히 지원됩니다:

```rust
use axum::{Router, routing::get};

fn create_router() -> Router {
    Router::new()
        .nest("/api/v1", api_v1_routes())
        .nest("/api/v2", api_v2_routes())
}

fn api_v1_routes() -> Router {
    Router::new()
        .route("/users", get(list_users))     // 최종 경로: /api/v1/users
        .route("/users/:id", get(get_user))   // 최종 경로: /api/v1/users/:id
}
```

> [!TIP]
> `.nest()`를 사용한 라우터 중첩은 자동으로 감지되고 경로가 올바르게 결합됩니다.

## 설정 옵션

### 파일 처리
- **포함 패턴**: `*.rs`
- **제외 패턴**:
  - `**/target` (Cargo 빌드 출력)
  - `**/.cargo` (Cargo 캐시)

### 검색 옵션
- `--type rust`: Rust 파일 검색 최적화

### 패턴 매칭
```lua
patterns = {
  GET = { "get\\s*\\(", "\\.route\\s*\\(.*get\\s*\\(" },
  POST = { "post\\s*\\(", "\\.route\\s*\\(.*post\\s*\\(" },
  PUT = { "put\\s*\\(", "\\.route\\s*\\(.*put\\s*\\(" },
  DELETE = { "delete\\s*\\(", "\\.route\\s*\\(.*delete\\s*\\(" },
  PATCH = { "patch\\s*\\(", "\\.route\\s*\\(.*patch\\s*\\(" },
}
```

## 메타데이터 향상

### 프레임워크별 태그
- `rust` (언어)
- `axum` (프레임워크)

### 메타데이터 필드
- `framework_version`: "axum"
- `language`: "rust"

### 신뢰도 점수
기본 신뢰도: 0.8

**신뢰도 향상:**
- +0.1 잘 형성된 경로 (`/`로 시작)
- +0.1 표준 HTTP 메서드

## 엔드포인트 구조 예제

### 기본 Axum 애플리케이션
```rust
use axum::{
    routing::{get, post, put, delete},
    http::StatusCode,
    Json, Router,
};
use serde_json::{json, Value};

async fn root() -> Json<Value> {
    Json(json!({ "message": "Hello World" }))
}

async fn list_users() -> Json<Value> {
    Json(json!({ "users": [] }))
}

async fn create_user() -> StatusCode {
    StatusCode::CREATED
}

async fn get_user() -> Json<Value> {
    Json(json!({ "user": { "id": 1 } }))
}

async fn update_user() -> Json<Value> {
    Json(json!({ "updated": true }))
}

async fn delete_user() -> StatusCode {
    StatusCode::NO_CONTENT
}

fn create_router() -> Router {
    Router::new()
        .route("/", get(root))
        // 감지됨: GET /
        .route("/users", get(list_users))
        // 감지됨: GET /users
        .route("/users", post(create_user))
        // 감지됨: POST /users
        .route("/users/:id", get(get_user))
        // 감지됨: GET /users/:id
        .route("/users/:id", put(update_user))
        // 감지됨: PUT /users/:id
        .route("/users/:id", delete(delete_user))
        // 감지됨: DELETE /users/:id
}
```

### 라우터 중첩 구조
```rust
use axum::{Router, routing::get};

fn create_app() -> Router {
    Router::new()
        .nest("/api", api_routes())
}

fn api_routes() -> Router {
    Router::new()
        .nest("/v1", v1_routes())
        .nest("/v2", v2_routes())
}

fn v1_routes() -> Router {
    Router::new()
        .nest("/users", user_routes())
        .nest("/posts", post_routes())
}

fn user_routes() -> Router {
    Router::new()
        .route("/", get(list_users))
        // 감지됨: GET /
        .route("/:id", get(get_user))
        // 감지됨: GET /:id
        .route("/", post(create_user))
        // 감지됨: POST /
}

fn post_routes() -> Router {
    Router::new()
        .route("/", get(list_posts))
        // 감지됨: GET /
        .route("/", post(create_post))
        // 감지됨: POST /
}
```

### 고급 라우트 패턴
```rust
fn create_router() -> Router {
    Router::new()
        .route("/users/:user_id/posts/:post_id", get(get_user_post))
        // 감지됨: GET /users/:user_id/posts/:post_id
        .route("/search", get(search_users))
        // 감지됨: GET /search
        .route("/webhook", axum::routing::any(handle_webhook))
        // 감지됨: ANY /webhook
}
```

## 문제 해결

### 일반적인 문제

> [!WARNING]
> **엔드포인트가 감지되지 않음**
> - `Cargo.toml`에서 Axum 의존성 확인
> - 라우트가 올바른 Axum 문법을 사용하는지 확인
> - 파일이 `.rs` 확장자를 가지는지 확인

> [!CAUTION]
> **중첩 라우트가 결합되지 않음**
> - `.nest()`로 라우터 중첩 확인
> - 중첩된 라우터가 올바르게 구조화되었는지 확인

> [!TIP]
> **누락된 핸들러 함수**
> - 핸들러 함수가 올바르게 참조되는지 확인
> - 라우팅 메서드가 `axum::routing`에서 import되었는지 확인

### 디버그 정보

프레임워크 디버깅을 활성화하여 감지 및 파싱 세부사항을 확인:
```lua
-- Neovim 설정에서
vim.g.endpoint_debug = true
```

## 통합 노트

> [!INFO]
> - Axum 0.6+ 지원
> - Tokio 비동기 런타임과 호환
> - 중첩된 라우터 및 미들웨어 지원
> - 라우트 매개변수 및 추출기 처리
> - Cargo 빌드 디렉토리를 검색에서 자동 제외
> - tower 미들웨어 및 서비스 지원
> - serde 직렬화 및 사용자 정의 추출기와 호환