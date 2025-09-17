# Phoenix Framework 지원

## 개요

Phoenix Framework 구현체는 Phoenix 애플리케이션을 포괄적으로 지원하며, 라우터와 컨트롤러 기반 구조를 포함합니다. Phoenix 프로젝트를 감지하고 다양한 라우트 정의 패턴을 파싱하여 API 엔드포인트 정보를 추출합니다.

## 프레임워크 세부사항

- **이름**: `phoenix`
- **언어**: Elixir
- **파일 확장자**: `*.ex`, `*.exs`
- **프레임워크 클래스**: `PhoenixFramework`

## 감지 전략

### 의존성 기반 감지

프레임워크는 Elixir 패키지 파일에서 특정 의존성을 찾아 Phoenix 프로젝트를 감지합니다:

**필수 의존성:**
- `phoenix`
- `phoenix_live_view`

**검색 대상 매니페스트 파일:**
- `mix.exs`
- `mix.lock`

> [!NOTE]
> Phoenix 감지는 의존성 기반 전략을 사용하여 Elixir 패키지 매니페스트 파일에서 Phoenix 관련 의존성을 검색합니다.

## 파싱 전략

### 어노테이션 기반 파싱 (라우트 매크로 파싱)

프레임워크는 라우트 매크로 기반 파싱을 사용하여 Phoenix 라우트 정의에서 엔드포인트 정보를 추출합니다.

### 지원되는 라우트 매크로

| 매크로 | HTTP 메서드 | 예제 |
|--------|-------------|------|
| `get` | GET | `get "/users", UserController, :index` |
| `post` | POST | `post "/users", UserController, :create` |
| `put` | PUT | `put "/users/:id", UserController, :update` |
| `patch` | PATCH | `patch "/users/:id", UserController, :update` |
| `delete` | DELETE | `delete "/users/:id", UserController, :delete` |
| `resources` | 다중 | `resources "/users", UserController` |

### 경로 추출 패턴

파서는 다양한 경로 정의 형식을 인식합니다:

1. **단순 경로**: `get "/users", UserController, :index`
2. **단일 따옴표**: `get '/users', UserController, :index`
3. **리소스**: `resources "/users", UserController`
4. **범위 라우트**: `scope "/api" do ... end`

### 라우트 범위 지원

Phoenix의 라우트 범위가 완전히 지원됩니다:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  scope "/api", MyAppWeb do
    pipe_through :api

    scope "/v1" do
      resources "/users", UserController, except: [:new, :edit]
      # 최종 경로: /api/v1/users (GET, POST)
      # /api/v1/users/:id (GET, PUT, PATCH, DELETE)
    end
  end
end
```

> [!TIP]
> 라우트 범위는 자동으로 감지되어 중첩 라우트와 결합됩니다.

## 설정 옵션

### 파일 처리
- **포함 패턴**: `*.ex`, `*.exs`
- **제외 패턴**:
  - `**/_build` (Mix 빌드 출력)
  - `**/deps` (의존성)
  - `**/priv` (프라이빗 자산)

### 검색 옵션
- `--type elixir`: Elixir 파일 검색 최적화

### 패턴 매칭
```lua
patterns = {
  GET = { "get\\s+", "resources\\s+" },
  POST = { "post\\s+", "resources\\s+" },
  PUT = { "put\\s+", "resources\\s+" },
  PATCH = { "patch\\s+", "resources\\s+" },
  DELETE = { "delete\\s+", "resources\\s+" },
}
```

## 메타데이터 향상

### 프레임워크별 태그
- `elixir` (언어)
- `phoenix` (프레임워크)

### 메타데이터 필드
- `framework_version`: "phoenix"
- `language`: "elixir"
- `controller`: 컨트롤러 모듈 이름
- `action`: 액션 함수 이름

### 신뢰도 점수
기본 신뢰도: 0.8

**신뢰도 향상:**
- +0.1 잘 형성된 경로 (`/`로 시작)
- +0.1 표준 HTTP 메서드

## 엔드포인트 구조 예제

### 기본 Phoenix 라우터
```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyAppWeb do
    pipe_through :api

    get "/", PageController, :index
    # 감지됨: GET /

    get "/users", UserController, :index
    # 감지됨: GET /users

    post "/users", UserController, :create
    # 감지됨: POST /users

    get "/users/:id", UserController, :show
    # 감지됨: GET /users/:id

    put "/users/:id", UserController, :update
    # 감지됨: PUT /users/:id

    delete "/users/:id", UserController, :delete
    # 감지됨: DELETE /users/:id
  end
end
```

### 리소스 기반 라우트
```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  scope "/api", MyAppWeb do
    pipe_through :api

    resources "/users", UserController
    # 감지됨: GET /api/users (index)
    # 감지됨: GET /api/users/:id (show)
    # 감지됨: POST /api/users (create)
    # 감지됨: PUT /api/users/:id (update)
    # 감지됨: PATCH /api/users/:id (update)
    # 감지됨: DELETE /api/users/:id (delete)

    resources "/users", UserController, only: [:index, :show]
    # 감지됨: GET /api/users (index)
    # 감지됨: GET /api/users/:id (show)

    resources "/posts", PostController, except: [:delete]
    # 감지됨: DELETE /api/posts/:id를 제외한 모든 것
  end
end
```

### 중첩 및 범위 라우트
```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  scope "/api", MyAppWeb do
    pipe_through :api

    scope "/v1" do
      resources "/users", V1.UserController do
        resources "/posts", V1.PostController
      end
    end
    # 감지됨: GET /api/v1/users
    # 감지됨: GET /api/v1/users/:user_id/posts
    # 등등.

    scope "/admin" do
      resources "/users", Admin.UserController
    end
    # 감지됨: GET /api/admin/users
    # 등등.
  end
end
```

### 고급 라우트 패턴
```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  scope "/", MyAppWeb do
    pipe_through :api

    get "/users/:user_id/posts/:id", PostController, :show
    # 감지됨: GET /users/:user_id/posts/:id

    get "/search", SearchController, :index
    # 감지됨: GET /search

    forward "/graphql", Absinthe.Plug,
      schema: MyAppWeb.Schema
    # 감지됨: forward 라우트 (표준 HTTP로 파싱되지 않을 수 있음)
  end
end
```

## 문제 해결

### 일반적인 문제

> [!WARNING]
> **엔드포인트가 감지되지 않음**
> - `mix.exs`에서 Phoenix 의존성 확인
> - 라우트가 올바른 Phoenix 문법을 사용하는지 확인
> - 파일이 `.ex` 또는 `.exs` 확장자를 가지는지 확인

> [!CAUTION]
> **범위 라우트가 결합되지 않음**
> - 적절한 `scope` 블록 중첩 확인
> - 범위 경로가 올바르게 정의되었는지 확인

> [!TIP]
> **누락된 리소스 액션**
> - `resources` 선언이 올바르게 형식화되었는지 확인
> - `only` 또는 `except` 옵션으로 인한 제한 확인

### 디버그 정보

프레임워크 디버깅을 활성화하여 감지 및 파싱 세부사항을 확인:
```lua
-- Neovim 설정에서
vim.g.endpoint_debug = true
```

## 통합 노트

> [!INFO]
> - Phoenix 1.5+ 지원
> - Phoenix LiveView와 호환
> - 전통적인 라우팅과 리소스 기반 라우팅 모두 지원
> - 중첩 리소스 및 범위 라우트 처리
> - 빌드 디렉토리 및 의존성을 검색에서 자동 제외
> - 파이프라인 및 플러그 설정 지원
> - Phoenix 채널 및 LiveView 라우트와 호환