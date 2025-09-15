# Django Framework Support

> **Language** | **언어**
> - 🇺🇸 [**English**](./README.md)
> - 🇰🇷 **한국어** (이 파일)

Django 프레임워크를 위한 endpoint.nvim 지원 기능을 설명합니다.

## 주요 기능

### 1. 엔드포인트 자동 발견

Django 프로젝트의 URLconf 구조를 분석하여 모든 엔드포인트를 자동으로 발견합니다.

#### 지원하는 URL 패턴:
- **path()**: `path('users/', views.user_list, name='user_list')`
- **re_path()**: `re_path(r'^users/(?P<user_id>\d+)/$', views.user_detail)`
- **url()**: `url(r'^legacy/', views.legacy_view)` (레거시 지원)
- **include()**: `path('api/', include('api.urls'))` (재귀적 분석)

#### 지원하는 뷰 타입:
- **함수 기반 뷰 (FBV)**: `def user_list(request):`
- **클래스 기반 뷰 (CBV)**: `UserListView.as_view()`
- **Django REST Framework ViewSets**: `UserViewSet`
- **문자열 참조**: `'users.views.user_detail'`

### 2. ROOT_URLCONF 자동 감지

Django 설정에서 ROOT_URLCONF를 자동으로 찾아 엔트리 포인트를 결정합니다.

```python
# settings.py에서 자동 감지
ROOT_URLCONF = 'myproject.urls'
```

### 3. HTTP 메서드별 정확한 라인 타겟팅

각 HTTP 메서드가 실제 구현된 정확한 라인으로 이동할 수 있습니다.

#### 클래스 기반 뷰 (CBV)

```python
class UserCreateView(CreateView):
    def get(self, request):        # ← GET 요청 시 이 라인으로 이동
        return JsonResponse({'form': 'create_form'})

    def post(self, request):       # ← POST 요청 시 이 라인으로 이동
        return JsonResponse({'message': 'User created'})
```

- `GET /api/users/create/` → `def get(self, request):` 라인
- `POST /api/users/create/` → `def post(self, request):` 라인

#### 함수 기반 뷰 - 조건문 있음

```python
def user_list(request):
    if request.method == 'GET':    # ← GET 요청 시 이 라인으로 이동
        return JsonResponse({'users': []})
    elif request.method == 'POST': # ← POST 요청 시 이 라인으로 이동
        return JsonResponse({'message': 'User created'})
```

- `GET /api/users/` → `if request.method == 'GET':` 라인
- `POST /api/users/` → `elif request.method == 'POST':` 라인

#### 함수 기반 뷰 - 조건문 없음

```python
def user_detail(request, pk):      # ← 모든 HTTP 메서드가 이 라인으로 이동
    return JsonResponse({'user_id': pk})
```

- `GET /api/users/1/` → `def user_detail(request, pk):` 라인
- `POST /api/users/1/` → `def user_detail(request, pk):` 라인

### 4. Django REST Framework (DRF) 지원

#### ViewSet과 Router 자동 분석

```python
# DRF Router 자동 감지
router = DefaultRouter()
router.register(r'users', UserViewSet)

class UserViewSet(viewsets.ModelViewSet):
    def list(self, request):       # ← GET /api/users/
    def create(self, request):     # ← POST /api/users/
    def retrieve(self, request, pk): # ← GET /api/users/{pk}/
    def update(self, request, pk): # ← PUT /api/users/{pk}/
    def destroy(self, request, pk): # ← DELETE /api/users/{pk}/

    @action(detail=False, methods=['get'])
    def active(self, request):     # ← GET /api/users/active/
```

#### @api_view 데코레이터 지원

```python
@api_view(['GET', 'POST'])
def api_endpoint(request):         # ← GET, POST 모두 이 라인으로 이동
    if request.method == 'GET':    # ← GET 요청 시 이 라인으로 이동
        return Response({'data': []})
    elif request.method == 'POST': # ← POST 요청 시 이 라인으로 이동
        return Response({'created': True})
```

### 5. URL 파라미터 표시 커스터마이징

URL 파라미터 표시 방식을 자유롭게 설정할 수 있습니다.

#### 설정 방법

```lua
require('endpoint').setup({
  frameworks = {
    django = {
      url_param_format = "%t:%v",    -- 내용 템플릿: %v=변수명, %t=타입
      url_param_fallback = "%v",     -- 타입 없을 때 사용할 템플릿
      url_param_brackets = "<>",     -- 브라켓 스타일
    }
  }
})
```

#### 다양한 표시 스타일

| 설정 | Django 원본 | 결과 |
|------|-------------|------|
| `%t:%v` + `<>` | `<int:pk>` | `<int:pk>` |
| `%v:%t` + `{}` | `<int:pk>` | `{pk:int}` |
| `%v` + `[]` | `<int:pk>` | `[pk]` |
| `%t-%v` + `()` | `<int:pk>` | `(int-pk)` |

#### 지원하는 브라켓 스타일:
- `"{}"` → `{pk:int}`
- `"<>"` → `<int:pk>`
- `"[]"` → `[pk:int]`
- `"()"` → `(int:pk)`
- 커스텀: `"⟨⟩"` → `⟨pk:int⟩`

### 6. 캐시 시스템

성능 향상을 위해 지능적인 캐시 시스템을 제공합니다.

- **전체 스캔 캐시**: 모든 엔드포인트를 한 번에 스캔하여 캐시
- **메서드별 필터링**: 캐시된 결과에서 특정 HTTP 메서드만 필터링
- **자동 무효화**: 30초 후 자동으로 캐시 무효화

## 지원하는 Django 버전

- Django 2.0+
- Django REST Framework 3.0+

## 파일 구조 요구사항

```
myproject/
├── settings.py          # ROOT_URLCONF 설정 필요
├── urls.py             # 메인 URLconf
└── apps/
    └── users/
        ├── urls.py     # 앱별 URLconf
        └── views.py    # 뷰 구현
```

## 설정 예시

### 기본 설정

```lua
require('endpoint').setup({
  frameworks = {
    django = {
      url_param_format = "%v:%t",      -- {pk:int} 스타일
      url_param_fallback = "%v",       -- {pk} 스타일
      url_param_brackets = "{}",       -- {} 브라켓
    }
  }
})
```

### Django 친화적 설정

```lua
require('endpoint').setup({
  frameworks = {
    django = {
      url_param_format = "%t:%v",      -- <int:pk> 스타일 (Django 원본 유지)
      url_param_fallback = "%v",       -- <pk> 스타일
      url_param_brackets = "<>",       -- <> 브라켓
    }
  }
})
```

## 트러블슈팅

### 엔드포인트가 발견되지 않는 경우

1. **ROOT_URLCONF 확인**: `settings.py`에서 올바른 ROOT_URLCONF가 설정되어 있는지 확인
2. **파일 경로 확인**: URLconf 파일들이 올바른 위치에 있는지 확인
3. **캐시 클리어**: `:lua package.loaded['endpoint.frameworks.django'] = nil` 후 재시도

### 잘못된 라인으로 이동하는 경우

1. **플러그인 재로드**: Neovim 재시작 또는 설정 재적용
2. **파일 동기화**: 수정된 파일이 저장되어 있는지 확인

## 개발자 정보

Django 프레임워크 지원은 다음 주요 기능들로 구성됩니다:

- **URL 패턴 파싱**: `parse_url_pattern()` 함수
- **뷰 분석**: `analyze_view_target()` 함수
- **CBV 분석**: `analyze_class_view()` 함수
- **함수 분석**: `analyze_function_view()` 함수
- **ViewSet 분석**: `analyze_viewset_class()` 함수
- **엔드포인트 생성**: `generate_view_endpoints()` 함수

자세한 구현 내용은 `lua/endpoint/frameworks/django.lua` 파일을 참조하세요.