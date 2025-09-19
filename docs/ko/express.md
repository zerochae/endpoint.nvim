# Express Framework 지원

## 개요

Express Framework 구현체는 Express.js 애플리케이션을 포괄적으로 지원하며, 미들웨어와 라우터 기반 구조를 포함합니다. Express 프로젝트를 감지하고 다양한 라우트 정의 패턴을 파싱하여 API 엔드포인트 정보를 추출합니다.

## 프레임워크 세부사항

- **이름**: `express`
- **언어**: JavaScript, TypeScript
- **파일 확장자**: `*.js`, `*.ts`
- **프레임워크 클래스**: `ExpressFramework`

## 감지 전략

### 의존성 기반 감지

프레임워크는 Node.js 패키지 파일에서 특정 의존성을 찾아 Express 프로젝트를 감지합니다:

**필수 의존성:**
- `express`
- `Express`

**검색 대상 매니페스트 파일:**
- `package.json`
- `package-lock.json`
- `yarn.lock`

> [!NOTE]
> Express 감지는 의존성 기반 전략을 사용하여 Node.js 패키지 매니페스트 파일에서 Express 관련 의존성을 검색합니다.

## 파싱 전략

### 어노테이션 기반 파싱 (라우트 파싱)

프레임워크는 라우트 기반 파싱을 사용하여 Express 라우트 정의에서 엔드포인트 정보를 추출합니다.

### 지원되는 라우트 메서드

| 메서드 | HTTP 메서드 | 예제 |
|--------|-------------|------|
| `app.get` | GET | `app.get('/users', handler)` |
| `app.post` | POST | `app.post('/users', handler)` |
| `app.put` | PUT | `app.put('/users/:id', handler)` |
| `app.delete` | DELETE | `app.delete('/users/:id', handler)` |
| `app.patch` | PATCH | `app.patch('/users/:id', handler)` |
| `router.get` | GET | `router.get('/items', handler)` |
| `router.post` | POST | `router.post('/items', handler)` |

### 경로 추출 패턴

파서는 다양한 경로 정의 형식을 인식합니다:

1. **단순 경로**: `app.get('/users', handler)`
2. **단일 따옴표**: `app.get("/users", handler)`
3. **템플릿 리터럴**: `app.get(`/users/${prefix}/items`, handler)`
4. **라우터 경로**: `router.get('/items', handler)`

### 라우터 지원

Express의 라우터 기반 구조가 완전히 지원됩니다:

```javascript
const express = require('express');
const router = express.Router();

// 마운트 경로가 있는 라우터
app.use('/api/users', router);

router.get('/', (req, res) => {});       // 최종 경로: /api/users/
router.get('/:id', (req, res) => {});    // 최종 경로: /api/users/:id
```

> [!TIP]
> 라우터 마운트 경로는 자동으로 감지되어 라우트 경로와 결합됩니다.

## 설정 옵션

### 파일 처리
- **포함 패턴**: `*.js`, `*.ts`
- **제외 패턴**:
  - `**/node_modules` (Node.js 패키지)
  - `**/dist` (빌드 출력)
  - `**/build` (빌드 출력)
  - `**/.next` (Next.js 빌드)

### 검색 옵션
- `--type js`: JavaScript 파일 검색 최적화
- `--type ts`: TypeScript 파일 검색 최적화

### 패턴 매칭
```lua
patterns = {
  GET = { "app\\.get", "router\\.get" },
  POST = { "app\\.post", "router\\.post" },
  PUT = { "app\\.put", "router\\.put" },
  DELETE = { "app\\.delete", "router\\.delete" },
  PATCH = { "app\\.patch", "router\\.patch" },
}
```

## 메타데이터 향상

### 프레임워크별 태그
- `javascript` 또는 `typescript` (언어)
- `express` (프레임워크)

### 메타데이터 필드
- `framework_version`: "express"
- `language`: "javascript" 또는 "typescript"

### 신뢰도 점수
기본 신뢰도: 0.8

**신뢰도 향상:**
- +0.1 잘 형성된 경로 (`/`로 시작)
- +0.1 표준 HTTP 메서드

## 엔드포인트 구조 예제

### 기본 Express 애플리케이션
```javascript
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello World');
});
// 감지됨: GET /

app.get('/users', (req, res) => {
  res.json({ users: [] });
});
// 감지됨: GET /users

app.post('/users', (req, res) => {
  res.json(req.body);
});
// 감지됨: POST /users

app.get('/users/:id', (req, res) => {
  res.json({ user: { id: req.params.id } });
});
// 감지됨: GET /users/:id

app.put('/users/:id', (req, res) => {
  res.json({ id: req.params.id, ...req.body });
});
// 감지됨: PUT /users/:id

app.delete('/users/:id', (req, res) => {
  res.json({ deleted: req.params.id });
});
// 감지됨: DELETE /users/:id
```

### 라우터 기반 구조
```javascript
const express = require('express');
const router = express.Router();

// 사용자 라우터
const userRouter = express.Router();
app.use('/api/users', userRouter);

userRouter.get('/', (req, res) => {
  res.json({ users: [] });
});
// 감지됨: GET /

userRouter.get('/:id', (req, res) => {
  res.json({ user: { id: req.params.id } });
});
// 감지됨: GET /:id

// 항목 라우터
const itemRouter = express.Router();
app.use('/api/items', itemRouter);

itemRouter.get('/', (req, res) => {
  res.json({ items: [] });
});
// 감지됨: GET /

itemRouter.post('/', (req, res) => {
  res.json(req.body);
});
// 감지됨: POST /
```

### 고급 경로 패턴
```javascript
app.get('/users/:userId/posts/:postId', (req, res) => {
  res.json({
    userId: req.params.userId,
    postId: req.params.postId
  });
});
// 감지됨: GET /users/:userId/posts/:postId

app.get('/search', (req, res) => {
  res.json({ query: req.query.q, results: [] });
});
// 감지됨: GET /search
```

## 문제 해결

### 일반적인 문제

> [!WARNING]
> **엔드포인트가 감지되지 않음**
> - `package.json`에서 Express 의존성 확인
> - 라우트가 올바른 Express 문법을 사용하는지 확인
> - 파일이 `.js` 또는 `.ts` 확장자를 가지는지 확인

> [!CAUTION]
> **라우터 경로가 결합되지 않음**
> - `app.use()`로 라우터 마운트 경로 확인
> - `express.Router()`가 올바르게 import되었는지 확인

> [!TIP]
> **누락된 미들웨어 라우트**
> - 라우트 정의만 감지되며 미들웨어는 감지되지 않음
> - 라우트가 표준 HTTP 메서드 이름을 사용하는지 확인

### 디버그 정보

프레임워크 디버깅을 활성화하여 감지 및 파싱 세부사항을 확인:
```lua
-- Neovim 설정에서
vim.g.endpoint_debug = true
```

## 통합 노트

> [!INFO]
> - Express 4.x 및 5.x 지원
> - CommonJS 및 ES 모듈 모두 호환
> - JavaScript 및 TypeScript 코드베이스 모두 지원
> - 중첩된 라우트 구조 및 라우트 매개변수 처리
> - Node.js 모듈 및 빌드 디렉토리를 검색에서 자동 제외
> - 템플릿 리터럴 경로 정의 지원
> - 미들웨어 및 라우트별 미들웨어와 호환