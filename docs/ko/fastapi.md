# FastAPI Framework 지원

## 개요

FastAPI Framework 구현체는 FastAPI 애플리케이션을 포괄적으로 지원하며, 비동기 엔드포인트와 라우터 기반 구조를 포함합니다. FastAPI 프로젝트를 감지하고 데코레이터 패턴을 파싱하여 API 엔드포인트 정보를 추출합니다.

## 프레임워크 세부사항

- **이름**: `fastapi`
- **언어**: Python
- **파일 확장자**: `*.py`
- **프레임워크 클래스**: `FastApiFramework`

## 감지 전략

### 의존성 기반 감지

프레임워크는 Python 패키지 파일에서 특정 의존성을 찾아 FastAPI 프로젝트를 감지합니다:

**필수 의존성:**
- `fastapi`
- `FastAPI`

**검색 대상 매니페스트 파일:**
- `requirements.txt`
- `pyproject.toml`
- `setup.py`
- `Pipfile`

> [!NOTE]
> FastAPI 감지는 의존성 기반 전략을 사용하여 패키지 매니페스트 파일에서 FastAPI 관련 의존성을 검색합니다.

## 파싱 전략

### 어노테이션 기반 파싱 (데코레이터 파싱)

프레임워크는 데코레이터 기반 파싱을 사용하여 FastAPI 데코레이터에서 엔드포인트 정보를 추출합니다.

### 지원되는 데코레이터

| 데코레이터 | HTTP 메서드 | 예제 |
|-----------|-------------|------|
| `@app.get` | GET | `@app.get("/users")` |
| `@app.post` | POST | `@app.post("/users")` |
| `@app.put` | PUT | `@app.put("/users/{user_id}")` |
| `@app.delete` | DELETE | `@app.delete("/users/{user_id}")` |
| `@app.patch` | PATCH | `@app.patch("/users/{user_id}")` |
| `@router.get` | GET | `@router.get("/items")` |
| `@router.post` | POST | `@router.post("/items")` |

### 경로 추출 패턴

파서는 다양한 경로 정의 형식을 인식합니다:

1. **단순 경로**: `@app.get("/users")`
2. **단일 따옴표**: `@app.get('/users')`
3. **F-문자열**: `@app.get(f"/users/{prefix}/items")`
4. **라우터 경로**: `@router.get("/items")`

### 라우터 지원

FastAPI의 라우터 기반 구조가 완전히 지원됩니다:

```python
from fastapi import APIRouter

router = APIRouter(prefix="/api/users")

@router.get("/")          # 최종 경로: /api/users/
async def get_users():
    pass

@router.get("/{user_id}") # 최종 경로: /api/users/{user_id}
async def get_user(user_id: int):
    pass
```

> [!TIP]
> 라우터 프리픽스는 자동으로 감지되어 메서드 경로와 결합됩니다.

## 설정 옵션

### 파일 처리
- **포함 패턴**: `*.py`
- **제외 패턴**:
  - `**/__pycache__` (Python 캐시)
  - `**/venv` (가상환경)
  - `**/.venv` (가상환경)
  - `**/site-packages` (Python 패키지)

### 검색 옵션
- `--type py`: Python 파일 검색 최적화

### 패턴 매칭
```lua
patterns = {
  GET = { "@app\\.get", "@router\\.get" },
  POST = { "@app\\.post", "@router\\.post" },
  PUT = { "@app\\.put", "@router\\.put" },
  DELETE = { "@app\\.delete", "@router\\.delete" },
  PATCH = { "@app\\.patch", "@router\\.patch" },
}
```

## 메타데이터 향상

### 프레임워크별 태그
- `python` (언어)
- `fastapi` (프레임워크)

### 메타데이터 필드
- `framework_version`: "fastapi"
- `language`: "python"

### 신뢰도 점수
기본 신뢰도: 0.7

**신뢰도 향상:**
- +0.15 명확한 HTTP 메서드 감지
- +0.15 명확한 경로 추출

## 엔드포인트 구조 예제

### 기본 FastAPI 애플리케이션
```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}
# 감지됨: GET /

@app.get("/users")
async def get_users():
    return {"users": []}
# 감지됨: GET /users

@app.post("/users")
async def create_user(user: dict):
    return user
# 감지됨: POST /users

@app.get("/users/{user_id}")
async def get_user(user_id: int):
    return {"user": {"id": user_id}}
# 감지됨: GET /users/{user_id}

@app.put("/users/{user_id}")
async def update_user(user_id: int, user: dict):
    return {"user_id": user_id, **user}
# 감지됨: PUT /users/{user_id}

@app.delete("/users/{user_id}")
async def delete_user(user_id: int):
    return {"deleted": user_id}
# 감지됨: DELETE /users/{user_id}
```

### 라우터 기반 구조
```python
from fastapi import APIRouter

# 사용자 라우터
user_router = APIRouter(prefix="/api/users", tags=["users"])

@user_router.get("/")
async def list_users():
    return {"users": []}
# 감지됨: GET /

@user_router.get("/{user_id}")
async def get_user(user_id: int):
    return {"user": {"id": user_id}}
# 감지됨: GET /{user_id}

# 항목 라우터
item_router = APIRouter(prefix="/api/items", tags=["items"])

@item_router.get("/")
async def list_items():
    return {"items": []}
# 감지됨: GET /

@item_router.post("/")
async def create_item(item: dict):
    return item
# 감지됨: POST /
```

### 고급 경로 패턴
```python
@app.get("/users/{user_id}/posts/{post_id}")
async def get_user_post(user_id: int, post_id: int):
    return {"user_id": user_id, "post_id": post_id}
# 감지됨: GET /users/{user_id}/posts/{post_id}

@app.get("/search")
async def search_users(q: str = ""):
    return {"query": q, "results": []}
# 감지됨: GET /search
```

## 문제 해결

### 일반적인 문제

> [!WARNING]
> **엔드포인트가 감지되지 않음**
> - `requirements.txt` 또는 `pyproject.toml`에서 FastAPI 의존성 확인
> - 데코레이터가 올바른 FastAPI 문법을 사용하는지 확인
> - 파일이 `.py` 확장자를 가지는지 확인

> [!CAUTION]
> **라우터 경로가 결합되지 않음**
> - 라우터 프리픽스 설정 확인
> - `APIRouter`가 올바르게 import되었는지 확인

> [!TIP]
> **누락된 비동기 함수**
> - 동기 및 비동기 함수 모두 지원됨
> - 데코레이터가 함수 정의 바로 위에 있는지 확인

### 디버그 정보

프레임워크 디버깅을 활성화하여 감지 및 파싱 세부사항을 확인:
```lua
-- Neovim 설정에서
vim.g.endpoint_debug = true
```

## 통합 노트

> [!INFO]
> - FastAPI 0.60+ 지원 (레거시 및 현대 문법 모두 지원)
> - async/await 및 동기 엔드포인트와 호환
> - 앱 레벨 및 라우터 레벨 데코레이터 모두 지원
> - 경로 매개변수 및 쿼리 매개변수 처리
> - Python 캐시 및 가상환경 자동 제외
> - f-문자열 경로 정의 지원
> - Pydantic 모델 및 의존성 주입과 호환