# Ktor Framework 지원

## 개요

Ktor Framework 구현체는 Ktor 애플리케이션을 포괄적으로 지원하며, 라우팅 DSL과 기능 기반 구조를 포함합니다. Ktor 프로젝트를 감지하고 다양한 라우트 정의 패턴을 파싱하여 API 엔드포인트 정보를 추출합니다.

## 프레임워크 세부사항

- **이름**: `ktor`
- **언어**: Kotlin
- **파일 확장자**: `*.kt`
- **프레임워크 클래스**: `KtorFramework`

## 감지 전략

### 의존성 기반 감지

프레임워크는 Kotlin/JVM 빌드 파일에서 특정 의존성을 찾아 Ktor 프로젝트를 감지합니다:

**필수 의존성:**
- `io.ktor:ktor-server-core`
- `ktor-server-core`
- `ktor-server`

**검색 대상 매니페스트 파일:**
- `build.gradle.kts`
- `build.gradle`
- `pom.xml`

> [!NOTE]
> Ktor 감지는 의존성 기반 전략을 사용하여 Kotlin/JVM 빌드 매니페스트 파일에서 Ktor 관련 의존성을 검색합니다.

## 파싱 전략

### 어노테이션 기반 파싱 (라우팅 DSL 파싱)

프레임워크는 라우팅 DSL 기반 파싱을 사용하여 Ktor 라우트 정의에서 엔드포인트 정보를 추출합니다.

### 지원되는 라우팅 메서드

| 메서드 | HTTP 메서드 | 예제 |
|--------|-------------|------|
| `get` | GET | `get("/users") { ... }` |
| `post` | POST | `post("/users") { ... }` |
| `put` | PUT | `put("/users/{id}") { ... }` |
| `delete` | DELETE | `delete("/users/{id}") { ... }` |
| `patch` | PATCH | `patch("/users/{id}") { ... }` |
| `route` | 다중 | `route("/api") { ... }` |

### 경로 추출 패턴

파서는 다양한 경로 정의 형식을 인식합니다:

1. **단순 경로**: `get("/users") { ... }`
2. **단일 따옴표**: `get('/users') { ... }`
3. **라우트 그룹**: `route("/api") { get("/users") { ... } }`
4. **매개변수 경로**: `get("/users/{id}") { ... }`

### 라우트 중첩 지원

Ktor의 라우팅 DSL 중첩이 완전히 지원됩니다:

```kotlin
import io.ktor.server.routing.*
import io.ktor.server.application.*

fun Application.configureRouting() {
    routing {
        route("/api/v1") {
            route("/users") {
                get {
                    // 최종 경로: /api/v1/users
                }
                post {
                    // 최종 경로: /api/v1/users
                }
                get("/{id}") {
                    // 최종 경로: /api/v1/users/{id}
                }
            }
        }
    }
}
```

> [!TIP]
> 중첩된 라우트 블록은 자동으로 감지되고 경로가 올바르게 결합됩니다.

## 설정 옵션

### 파일 처리
- **포함 패턴**: `*.kt`
- **제외 패턴**:
  - `**/build` (빌드 출력)
  - `**/.gradle` (Gradle 캐시)
  - `**/target` (Maven target)

### 검색 옵션
- `--type kotlin`: Kotlin 파일 검색 최적화

### 패턴 매칭
```lua
patterns = {
  GET = { "get\\s*\\(", "get\\s*\\{" },
  POST = { "post\\s*\\(", "post\\s*\\{" },
  PUT = { "put\\s*\\(", "put\\s*\\{" },
  DELETE = { "delete\\s*\\(", "delete\\s*\\{" },
  PATCH = { "patch\\s*\\(", "patch\\s*\\{" },
}
```

## 메타데이터 향상

### 프레임워크별 태그
- `kotlin` (언어)
- `ktor` (프레임워크)

### 메타데이터 필드
- `framework_version`: "ktor"
- `language`: "kotlin"

### 신뢰도 점수
기본 신뢰도: 0.8

**신뢰도 향상:**
- +0.1 잘 형성된 경로 (`/`로 시작)
- +0.1 표준 HTTP 메서드

## 엔드포인트 구조 예제

### 기본 Ktor 애플리케이션
```kotlin
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.plugins.contentnegotiation.*

fun Application.configureRouting() {
    install(ContentNegotiation) {
        json()
    }

    routing {
        get("/") {
            call.respondText("Hello World!")
        }
        // 감지됨: GET /

        get("/users") {
            call.respond(mapOf("users" to listOf<String>()))
        }
        // 감지됨: GET /users

        post("/users") {
            call.respond(mapOf("created" to true))
        }
        // 감지됨: POST /users

        get("/users/{id}") {
            val id = call.parameters["id"]
            call.respond(mapOf("user" to mapOf("id" to id)))
        }
        // 감지됨: GET /users/{id}

        put("/users/{id}") {
            val id = call.parameters["id"]
            call.respond(mapOf("updated" to id))
        }
        // 감지됨: PUT /users/{id}

        delete("/users/{id}") {
            val id = call.parameters["id"]
            call.respond(mapOf("deleted" to id))
        }
        // 감지됨: DELETE /users/{id}
    }
}
```

### 중첩 라우트 구조
```kotlin
fun Application.configureRouting() {
    routing {
        route("/api") {
            route("/v1") {
                route("/users") {
                    get {
                        call.respond(mapOf("users" to listOf<String>()))
                    }
                    // 감지됨: GET /

                    get("/{id}") {
                        val id = call.parameters["id"]
                        call.respond(mapOf("user" to mapOf("id" to id)))
                    }
                    // 감지됨: GET /{id}

                    post {
                        call.respond(mapOf("created" to true))
                    }
                    // 감지됨: POST /
                }

                route("/posts") {
                    get {
                        call.respond(mapOf("posts" to listOf<String>()))
                    }
                    // 감지됨: GET /

                    post {
                        call.respond(mapOf("created" to true))
                    }
                    // 감지됨: POST /
                }
            }
        }
    }
}
```

## 문제 해결

### 일반적인 문제

> [!WARNING]
> **엔드포인트가 감지되지 않음**
> - `build.gradle.kts` 또는 `pom.xml`에서 Ktor 의존성 확인
> - 라우팅 DSL이 올바른 Ktor 문법을 사용하는지 확인
> - 파일이 `.kt` 확장자를 가지는지 확인

> [!CAUTION]
> **중첩 라우트가 결합되지 않음**
> - 적절한 `route` 블록 중첩 확인
> - 라우팅 DSL이 올바르게 구조화되었는지 확인

> [!TIP]
> **누락된 라우트 핸들러**
> - 라우트 핸들러가 라우팅 블록 내에 정의되었는지 확인
> - HTTP 메서드 함수가 올바르게 호출되는지 확인

### 디버그 정보

프레임워크 디버깅을 활성화하여 감지 및 파싱 세부사항을 확인:
```lua
-- Neovim 설정에서
vim.g.endpoint_debug = true
```

## 통합 노트

> [!INFO]
> - Ktor 2.x 지원
> - Kotlin/JVM 및 Kotlin/Native와 호환
> - 중첩된 라우팅 DSL 및 기능 지원
> - 라우트 매개변수 및 쿼리 매개변수 처리
> - 빌드 디렉토리 및 캐시를 검색에서 자동 제외
> - 콘텐츠 협상 및 직렬화 지원
> - Ktor 플러그인 및 사용자 정의 기능과 호환