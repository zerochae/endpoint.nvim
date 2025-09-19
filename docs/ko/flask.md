# Flask Framework 지원

## 개요

Flask Framework 구현체는 Flask 애플리케이션을 포괄적으로 지원하며, 데코레이터와 블루프린트 기반 구조를 포함합니다. Flask 프로젝트를 감지하고 다양한 라우트 정의 패턴을 파싱하여 API 엔드포인트 정보를 추출합니다.

## 프레임워크 세부사항

- **이름**: `flask`
- **언어**: Python
- **파일 확장자**: `*.py`
- **프레임워크 클래스**: `FlaskFramework`

## 감지 전략

### 의존성 기반 감지

프레임워크는 Python 패키지 파일에서 특정 의존성을 찾아 Flask 프로젝트를 감지합니다:

**필수 의존성:**
- `flask`
- `Flask`

**검색 대상 매니페스트 파일:**
- `requirements.txt`
- `pyproject.toml`
- `setup.py`
- `Pipfile`

> [!NOTE]
> Flask 감지는 의존성 기반 전략을 사용하여 Python 패키지 매니페스트 파일에서 Flask 관련 의존성을 검색합니다.

## 파싱 전략

### 어노테이션 기반 파싱 (데코레이터 파싱)

프레임워크는 데코레이터 기반 파싱을 사용하여 Flask 라우트 데코레이터에서 엔드포인트 정보를 추출합니다.

### 지원되는 데코레이터

| 데코레이터 | HTTP 메서드 | 예제 |
|-----------|-------------|------|
| `@app.route` | 다중/지정됨 | `@app.route('/users', methods=['GET'])` |
| `@app.get` | GET | `@app.get('/users')` |
| `@app.post` | POST | `@app.post('/users')` |
| `@app.put` | PUT | `@app.put('/users/<id>')` |
| `@app.delete` | DELETE | `@app.delete('/users/<id>')` |
| `@app.patch` | PATCH | `@app.patch('/users/<id>')` |
| `@bp.route` | 다중/지정됨 | `@bp.route('/items', methods=['GET'])` |

### 경로 추출 패턴

파서는 다양한 경로 정의 형식을 인식합니다:

1. **단순 경로**: `@app.route('/users')`
2. **단일 따옴표**: `@app.route("/users")`
3. **메서드 매개변수**: `@app.route('/users', methods=['GET', 'POST'])`
4. **블루프린트 라우트**: `@bp.route('/items')`

### 블루프린트 지원

Flask의 블루프린트 기반 구조가 완전히 지원됩니다:

```python
from flask import Blueprint

bp = Blueprint('users', __name__, url_prefix='/api/users')

@bp.route('/')                    # 최종 경로: /api/users/
def get_users():
    pass

@bp.route('/<int:user_id>')      # 최종 경로: /api/users/<int:user_id>
def get_user(user_id):
    pass
```

> [!TIP]
> 블루프린트 url_prefix는 자동으로 감지되어 라우트 경로와 결합됩니다.

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
  GET = { "@app\\.get", "@bp\\.get", "@app\\.route.*GET", "@bp\\.route.*GET" },
  POST = { "@app\\.post", "@bp\\.post", "@app\\.route.*POST", "@bp\\.route.*POST" },
  PUT = { "@app\\.put", "@bp\\.put", "@app\\.route.*PUT", "@bp\\.route.*PUT" },
  DELETE = { "@app\\.delete", "@bp\\.delete", "@app\\.route.*DELETE", "@bp\\.route.*DELETE" },
  PATCH = { "@app\\.patch", "@bp\\.patch", "@app\\.route.*PATCH", "@bp\\.route.*PATCH" },
}
```

## 메타데이터 향상

### 프레임워크별 태그
- `python` (언어)
- `flask` (프레임워크)

### 메타데이터 필드
- `framework_version`: "flask"
- `language`: "python"

### 신뢰도 점수
기본 신뢰도: 0.8

**신뢰도 향상:**
- +0.1 잘 형성된 경로 (`/`로 시작)
- +0.1 표준 HTTP 메서드

## 엔드포인트 구조 예제

### 기본 Flask 애플리케이션
```python
from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
    return 'Hello World'
# 감지됨: GET / (기본 메서드)

@app.route('/users')
def get_users():
    return {'users': []}
# 감지됨: GET /users

@app.route('/users', methods=['POST'])
def create_user():
    return request.json
# 감지됨: POST /users

@app.get('/users/<int:user_id>')
def get_user(user_id):
    return {'user': {'id': user_id}}
# 감지됨: GET /users/<int:user_id>

@app.put('/users/<int:user_id>')
def update_user(user_id):
    return {'user_id': user_id, **request.json}
# 감지됨: PUT /users/<int:user_id>

@app.delete('/users/<int:user_id>')
def delete_user(user_id):
    return {'deleted': user_id}
# 감지됨: DELETE /users/<int:user_id>
```

### 블루프린트 기반 구조
```python
from flask import Blueprint

# 사용자 블루프린트
user_bp = Blueprint('users', __name__, url_prefix='/api/users')

@user_bp.route('/')
def list_users():
    return {'users': []}
# 감지됨: GET /

@user_bp.route('/<int:user_id>')
def get_user(user_id):
    return {'user': {'id': user_id}}
# 감지됨: GET /<int:user_id>

# 항목 블루프린트
item_bp = Blueprint('items', __name__, url_prefix='/api/items')

@item_bp.route('/')
def list_items():
    return {'items': []}
# 감지됨: GET /

@item_bp.route('/', methods=['POST'])
def create_item():
    return request.json
# 감지됨: POST /
```

### 고급 경로 패턴
```python
@app.route('/users/<int:user_id>/posts/<int:post_id>')
def get_user_post(user_id, post_id):
    return {'user_id': user_id, 'post_id': post_id}
# 감지됨: GET /users/<int:user_id>/posts/<int:post_id>

@app.route('/search')
def search_users():
    return {'query': request.args.get('q', ''), 'results': []}
# 감지됨: GET /search

@app.route('/users', methods=['GET', 'POST'])
def users():
    if request.method == 'GET':
        return {'users': []}
    else:
        return request.json
# 감지됨: GET /users, POST /users (다중 메서드)
```

## 문제 해결

### 일반적인 문제

> [!WARNING]
> **엔드포인트가 감지되지 않음**
> - `requirements.txt` 또는 `pyproject.toml`에서 Flask 의존성 확인
> - 데코레이터가 올바른 Flask 문법을 사용하는지 확인
> - 파일이 `.py` 확장자를 가지는지 확인

> [!CAUTION]
> **블루프린트 경로가 결합되지 않음**
> - 블루프린트 url_prefix 설정 확인
> - `Blueprint`가 올바르게 import되었는지 확인

> [!TIP]
> **누락된 메서드별 데코레이터**
> - `@app.route` 및 `@app.get` 스타일 데코레이터 모두 지원됨
> - 데코레이터가 함수 정의 바로 위에 있는지 확인

### 디버그 정보

프레임워크 디버깅을 활성화하여 감지 및 파싱 세부사항을 확인:
```lua
-- Neovim 설정에서
vim.g.endpoint_debug = true
```

## 통합 노트

> [!INFO]
> - Flask 1.0+ 지원 (레거시 및 현대 문법 모두 지원)
> - Flask-RESTful 확장과 호환
> - 앱 레벨 및 블루프린트 레벨 데코레이터 모두 지원
> - 경로 매개변수 및 쿼리 매개변수 처리
> - Python 캐시 및 가상환경 자동 제외
> - 단일 라우트에서 여러 HTTP 메서드 지원
> - Flask 확장 및 미들웨어와 호환