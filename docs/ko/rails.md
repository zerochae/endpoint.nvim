# Rails Framework 지원

## 개요

Rails Framework 구현체는 Ruby on Rails 애플리케이션을 포괄적으로 지원하며, RESTful 라우팅과 컨트롤러 기반 구조를 포함합니다. Rails 프로젝트를 감지하고 다양한 라우트 정의 패턴을 파싱하여 API 엔드포인트 정보를 추출합니다.

## 프레임워크 세부사항

- **이름**: `rails`
- **언어**: Ruby
- **파일 확장자**: `*.rb`
- **프레임워크 클래스**: `RailsFramework`

## 감지 전략

### 의존성 기반 감지

프레임워크는 특정 파일과 의존성을 찾아 Rails 프로젝트를 감지합니다:

**필수 의존성:**
- `rails`
- `actionpack`
- `railties`

**검색 대상 매니페스트 파일:**
- `Gemfile`
- `Gemfile.lock`
- `config/application.rb`
- `config/routes.rb`

> [!NOTE]
> Rails 감지는 의존성 기반 전략을 사용하여 Ruby 패키지 매니페스트 파일과 설정 파일에서 Rails 관련 의존성을 검색합니다.

## 파싱 전략

### 어노테이션 기반 파싱 (라우트 파싱)

프레임워크는 라우트 기반 파싱을 사용하여 Rails 라우트 정의와 컨트롤러 액션에서 엔드포인트 정보를 추출합니다.

### 지원되는 라우트 메서드

| 메서드 | HTTP 메서드 | 예제 |
|--------|-------------|------|
| `get` | GET | `get '/users', to: 'users#index'` |
| `post` | POST | `post '/users', to: 'users#create'` |
| `put` | PUT | `put '/users/:id', to: 'users#update'` |
| `patch` | PATCH | `patch '/users/:id', to: 'users#update'` |
| `delete` | DELETE | `delete '/users/:id', to: 'users#destroy'` |
| `resources` | 다중 | `resources :users` |
| `resource` | 다중 | `resource :profile` |

### 경로 추출 패턴

파서는 다양한 경로 정의 형식을 인식합니다:

1. **직접 라우트**: `get '/users', to: 'users#index'`
2. **단일 따옴표**: `get "/users", to: "users#index"`
3. **리소스**: `resources :users`
4. **중첩 리소스**: `resources :users do ... end`
5. **네임스페이스 라우트**: `namespace :api do ... end`

### 리소스와 RESTful 라우트

Rails의 리소스풀 라우팅이 완전히 지원됩니다:

```ruby
Rails.application.routes.draw do
  resources :users do
    resources :posts
  end
end
```

다음을 생성합니다:
- `GET /users` (index)
- `GET /users/:id` (show)
- `POST /users` (create)
- `PUT /users/:id` (update)
- `PATCH /users/:id` (update)
- `DELETE /users/:id` (destroy)
- `GET /users/:user_id/posts` (중첩 index)
- 등등.

> [!TIP]
> Rails 리소스 라우트는 자동으로 RESTful 엔드포인트로 확장됩니다.

## 설정 옵션

### 파일 처리
- **포함 패턴**: `*.rb`
- **제외 패턴**:
  - `**/vendor` (Vendor gems)
  - `**/tmp` (임시 파일)
  - `**/log` (로그 파일)
  - `**/.bundle` (Bundle 캐시)

### 검색 옵션
- `--type ruby`: Ruby 파일 검색 최적화

### 패턴 매칭
```lua
patterns = {
  GET = { "get\\s+['\"]", "resources\\s+:", "resource\\s+:" },
  POST = { "post\\s+['\"]", "resources\\s+:", "resource\\s+:" },
  PUT = { "put\\s+['\"]", "resources\\s+:" },
  PATCH = { "patch\\s+['\"]", "resources\\s+:" },
  DELETE = { "delete\\s+['\"]", "resources\\s+:" },
}
```

## 메타데이터 향상

### 프레임워크별 태그
- `ruby` (언어)
- `rails` (프레임워크)

### 메타데이터 필드
- `framework_version`: "rails"
- `language`: "ruby"
- `controller`: 컨트롤러 이름 (라우트에서 추출)
- `action`: 액션 이름 (라우트에서 추출)

### 신뢰도 점수
기본 신뢰도: 0.8

**신뢰도 향상:**
- +0.1 잘 형성된 경로 (`/`로 시작)
- +0.1 표준 RESTful 액션

## 엔드포인트 구조 예제

### 기본 라우트 설정
```ruby
Rails.application.routes.draw do
  root 'home#index'
  # 감지됨: GET[home#index] /

  get '/users', to: 'users#index'
  # 감지됨: GET[users#index] /users

  post '/users', to: 'users#create'
  # 감지됨: POST[users#create] /users

  get '/users/:id', to: 'users#show'
  # 감지됨: GET[users#show] /users/:id

  put '/users/:id', to: 'users#update'
  # 감지됨: PUT[users#update] /users/:id

  delete '/users/:id', to: 'users#destroy'
  # 감지됨: DELETE[users#destroy] /users/:id
end
```

### 리소스풀 라우트
```ruby
Rails.application.routes.draw do
  resources :users
  # 감지됨: GET[users#index] /users
  # 감지됨: GET[users#show] /users/:id
  # 감지됨: POST[users#create] /users
  # 감지됨: PUT[users#update] /users/:id
  # 감지됨: PATCH[users#update] /users/:id
  # 감지됨: DELETE[users#destroy] /users/:id
  # 감지됨: GET[users#new] /users/new
  # 감지됨: GET[users#edit] /users/:id/edit

  resources :users, only: [:index, :show]
  # 감지됨: GET[users#index] /users
  # 감지됨: GET[users#show] /users/:id

  resources :users, except: [:destroy]
  # 감지됨: DELETE[users#destroy] /users/:id를 제외한 모든 것
end
```

### 중첩 및 네임스페이스 라우트
```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users do
        resources :posts
      end
    end
  end
  # 감지됨: GET[users#index] /api/v1/users
  # 감지됨: GET[posts#index] /api/v1/users/:user_id/posts
  # 등등.

  resources :users do
    member do
      get :profile
    end
    collection do
      get :search
    end
  end
  # 감지됨: GET[users#profile] /users/:id/profile (member)
  # 감지됨: GET[users#search] /users/search (collection)

  resources :posts do
    resources :comments, except: [:show]
  end
  # 감지됨: GET[comments#index] /posts/:post_id/comments (중첩)
  # 감지됨: POST[comments#create] /posts/:post_id/comments (중첩)
  # 감지됨: GET[comments#edit] /posts/:post_id/comments/:id/edit (중첩)
  # 감지됨: PUT[comments#update] /posts/:post_id/comments/:id (중첩)
  # 감지됨: DELETE[comments#destroy] /posts/:post_id/comments/:id (중첩)
  # 참고: except: [:show]로 인해 show 액션 제외됨
end
```

### 고급 라우트 패턴
```ruby
Rails.application.routes.draw do
  get '/users/:user_id/posts/:id', to: 'posts#show'
  # 감지됨: GET[posts#show] /users/:user_id/posts/:id

  get '/search', to: 'search#index'
  # 감지됨: GET[search#index] /search

  scope '/admin' do
    resources :users
  end
  # 감지됨: GET[users#index] /admin/users
  # 등등.
end
```

## 향상된 표시 형식

### Rails 전용 엔드포인트 표시
엔드포인트가 이제 Rails 개발자에게 친숙한 `controller#action` 표기법을 사용합니다:

**형식**: `METHOD[controller#action] /path`

예제:
- `GET[users#index] /users`
- `POST[users#create] /users`
- `GET[users#show] /users/:id`
- `GET[users#profile] /users/:id/profile` (member 라우트)
- `GET[users#search] /users/search` (collection 라우트)
- `GET[comments#index] /posts/:post_id/comments` (중첩 라우트)
- `GET[home#index] /` (root 라우트)

### 시각적 하이라이팅
Telescope picker에서 `METHOD[controller#action]` 부분이 하이라이팅되어 쉽게 식별할 수 있습니다:
- **하이라이팅**: `GET[users#profile]`
- **일반**: `/users/:id/profile`

이 형식은 Rails `routes` 명령어 출력과 일치하여 Rails 개발자에게 즉시 친숙합니다.

## 문제 해결

### 일반적인 문제

> [!WARNING]
> **엔드포인트가 감지되지 않음**
> - `Gemfile`에서 Rails 의존성 확인
> - `config/routes.rb`가 존재하고 라우트를 포함하는지 확인
> - 파일이 `.rb` 확장자를 가지는지 확인

> [!CAUTION]
> **중첩 라우트가 감지되지 않음**
> - 라우트 파일에서 올바른 중첩 문법 확인
> - 누락된 `do...end` 블록 확인

> [!TIP]
> **누락된 RESTful 액션**
> - `resources` 선언이 올바르게 형식화되었는지 확인
> - `only` 또는 `except` 옵션으로 인한 제한 확인

### 디버그 정보

프레임워크 디버깅을 활성화하여 감지 및 파싱 세부사항을 확인:
```lua
-- Neovim 설정에서
vim.g.endpoint_debug = true
```

## 고급 기능

### 중첩 리소스 해석
프레임워크는 이제 정확한 경로 생성과 함께 깊게 중첩된 리소스에 대한 포괄적인 지원을 제공합니다:

```ruby
resources :posts do
  resources :comments do
    resources :replies
  end
end
```
- **생성됨**: `/posts/:post_id/comments/:comment_id/replies`
- **링크 대상**: 실제 컨트롤러 액션 구현 (routes.rb가 아닌)
- **지원 사항**: 중첩 컨텍스트에서 `only` 및 `except` 옵션

### 컨트롤러 액션 링크
엔드포인트 프리뷰가 이제 라우트 정의가 아닌 컨트롤러 구현을 직접 링크합니다:

- **이전**: `GET /posts/:post_id/comments` → `config/routes.rb:16`
- **이후**: `GET /posts/:post_id/comments` → `app/controllers/comments_controller.rb:5` (def index)

### 정확한 컬럼 위치
프리뷰 위치가 이제 정확한 문자 단위로 정확합니다:
- **이전**: 프리뷰에서 `f destroy`로 잘림
- **이후**: 완전한 `def destroy` 메서드 시그니처 표시

### Member 및 Collection 라우트 컨텍스트
Member 및 collection 라우트가 부모 리소스 컨텍스트를 유지합니다:

```ruby
resources :users do
  member do
    get :profile      # → GET /users/:id/profile
    patch :activate   # → PATCH /users/:id/activate
  end
  collection do
    get :search       # → GET /users/search
    post :bulk_create # → POST /users/bulk_create
  end
end
```

## 통합 노트

> [!INFO]
> - Rails 5.x, 6.x, 7.x 지원
> - Rails API 모드와 호환
> - 전통적인 라우팅과 리소스풀 라우팅 모두 지원
> - 중첩 리소스 및 네임스페이스 라우트 처리
> - vendor gems 및 임시 파일을 검색에서 자동 제외
> - member 및 collection 라우트 지원
> - Rails 엔진 및 마운트 가능한 앱과 호환
> - **신규**: 정확한 중첩 리소스 경로 생성
> - **신규**: 모든 라우트 타입에 대한 직접 컨트롤러 액션 링크
> - **신규**: 올바른 컬럼 값으로 정확한 프리뷰 위치