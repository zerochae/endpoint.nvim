# Django Framework 지원

## 개요

Django Framework 구현체는 Django 애플리케이션을 포괄적으로 지원하며, URL 패턴과 뷰 기반 구조를 포함합니다. Django 프로젝트를 감지하고 다양한 URL 정의 패턴을 파싱하여 API 엔드포인트 정보를 추출합니다.

## 프레임워크 세부사항

- **이름**: `django`
- **언어**: Python
- **파일 확장자**: `*.py`
- **프레임워크 클래스**: `DjangoFramework`

## 감지 전략

### 의존성 기반 감지

프레임워크는 Python 패키지 파일에서 특정 의존성을 찾아 Django 프로젝트를 감지합니다:

**필수 의존성:**
- `django`
- `Django`

**검색 대상 매니페스트 파일:**
- `requirements.txt`
- `pyproject.toml`
- `setup.py`
- `Pipfile`
- `manage.py`
- `settings.py`

> [!NOTE]
> Django 감지는 의존성 기반 전략을 사용하여 Python 패키지 매니페스트 파일과 Django 특정 파일에서 Django 관련 의존성을 검색합니다.

## 파싱 전략

### 어노테이션 기반 파싱 (URL 패턴 파싱)

프레임워크는 URL 패턴 기반 파싱을 사용하여 Django URL 설정에서 엔드포인트 정보를 추출합니다.

### 지원되는 URL 패턴

| 패턴 타입 | HTTP 메서드 | 예제 |
|-----------|-------------|------|
| `path()` | 다중 | `path('users/', views.user_list)` |
| `re_path()` | 다중 | `re_path(r'^users/$', views.user_list)` |
| `url()` | 다중 | `url(r'^users/$', views.user_list)` |
| 클래스 기반 뷰 | 다중 | `path('users/', UserListView.as_view())` |

### 경로 추출 패턴

파서는 다양한 경로 정의 형식을 인식합니다:

1. **단순 경로**: `path('users/', views.user_list)`
2. **단일 따옴표**: `path("users/", views.user_list)`
3. **정규식 경로**: `re_path(r'^users/(?P<id>\\d+)/$', views.user_detail)`
4. **Include 패턴**: `path('api/', include('api.urls'))`

### URL Include 지원

Django의 URL include 패턴이 지원됩니다:

```python
# main/urls.py
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),
    path('api/posts/', include('posts.urls')),
]

# users/urls.py
urlpatterns = [
    path('', views.user_list),           # 최종 경로: /api/users/
    path('<int:pk>/', views.user_detail), # 최종 경로: /api/users/<int:pk>/
]
```

> [!TIP]
> URL include 경로는 자동으로 감지되어 중첩 패턴과 결합됩니다.

## 설정 옵션

### 파일 처리
- **포함 패턴**: `*.py`
- **제외 패턴**:
  - `**/__pycache__` (Python 캐시)
  - `**/venv` (가상환경)
  - `**/.venv` (가상환경)
  - `**/site-packages` (Python 패키지)
  - `**/migrations` (Django 마이그레이션)

### 검색 옵션
- `--type py`: Python 파일 검색 최적화

### 패턴 매칭
```lua
patterns = {
  GET = { "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(" },
  POST = { "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(" },
  PUT = { "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(" },
  DELETE = { "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(" },
  PATCH = { "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(" },
}
```

## 메타데이터 향상

### 프레임워크별 태그
- `python` (언어)
- `django` (프레임워크)

### 메타데이터 필드
- `framework_version`: "django"
- `language`: "python"
- `view_name`: 뷰 함수 또는 클래스 이름
- `app_name`: Django 앱 이름 (감지 가능한 경우)

### 신뢰도 점수
기본 신뢰도: 0.7

**신뢰도 향상:**
- +0.15 명확한 뷰 함수 감지
- +0.15 잘 형성된 URL 패턴

## 엔드포인트 구조 예제

### 함수 기반 뷰
```python
from django.urls import path
from . import views

urlpatterns = [
    path('', views.user_list, name='user-list'),
    # 감지됨: GET/POST /users/ (함수 기반)

    path('<int:pk>/', views.user_detail, name='user-detail'),
    # 감지됨: GET/PUT/DELETE /users/<int:pk>/

    path('search/', views.search_users, name='user-search'),
    # 감지됨: GET /users/search/
]
```

### 클래스 기반 뷰
```python
from django.urls import path
from .views import UserListView, UserDetailView

urlpatterns = [
    path('', UserListView.as_view(), name='user-list'),
    # 감지됨: GET/POST /users/ (클래스 기반)

    path('<int:pk>/', UserDetailView.as_view(), name='user-detail'),
    # 감지됨: GET/PUT/DELETE /users/<int:pk>/
]
```

### Django REST Framework
```python
from rest_framework.routers import DefaultRouter
from .views import UserViewSet

router = DefaultRouter()
router.register(r'users', UserViewSet)
urlpatterns = router.urls
# 감지됨: /users/를 위한 여러 RESTful 엔드포인트
```

### 고급 URL 패턴
```python
from django.urls import path, re_path, include

urlpatterns = [
    path('users/<int:user_id>/posts/<int:post_id>/',
         views.user_post_detail),
    # 감지됨: GET/PUT/DELETE /users/<int:user_id>/posts/<int:post_id>/

    re_path(r'^search/(?P<query>[\\w-]+)/$', views.search),
    # 감지됨: GET /search/<query>/

    path('api/v1/', include('api.urls')),
    # 감지됨: /api/v1/ 프리픽스로 api.urls에서 포함
]
```

## 문제 해결

### 일반적인 문제

> [!WARNING]
> **엔드포인트가 감지되지 않음**
> - `requirements.txt` 또는 `pyproject.toml`에서 Django 의존성 확인
> - URL 패턴이 올바른 Django 문법을 사용하는지 확인
> - 파일이 `.py` 확장자를 가지고 `urlpatterns`를 포함하는지 확인

> [!CAUTION]
> **Include 경로가 결합되지 않음**
> - `include()` 문이 올바르게 형식화되었는지 확인
> - 포함된 URL 파일이 존재하고 접근 가능한지 확인

> [!TIP]
> **누락된 ViewSet 엔드포인트**
> - DRF ViewSet이 URL 파일에서 감지되지 않을 수 있음
> - 라우터 등록 및 사용자 정의 URL 패턴 확인

### 디버그 정보

프레임워크 디버깅을 활성화하여 감지 및 파싱 세부사항을 확인:
```lua
-- Neovim 설정에서
vim.g.endpoint_debug = true
```

## 통합 노트

> [!INFO]
> - Django 2.x, 3.x, 4.x 지원
> - Django REST Framework와 호환
> - 함수 기반 및 클래스 기반 뷰 모두 지원
> - URL include 및 중첩 패턴 처리
> - Django 마이그레이션 및 Python 캐시를 검색에서 자동 제외
> - 정규식 URL 패턴 지원
> - Django 앱 및 프로젝트 구조와 호환