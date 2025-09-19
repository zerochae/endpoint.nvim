# Spring Framework 지원

## 개요

Spring Framework 구현체는 Spring Boot 애플리케이션을 포괄적으로 지원하며, REST 컨트롤러와 웹 엔드포인트를 포함합니다. Spring 프로젝트를 감지하고 다양한 어노테이션 패턴을 파싱하여 API 엔드포인트 정보를 추출합니다.

## 프레임워크 세부사항

- **이름**: `spring`
- **언어**: Java, Kotlin
- **파일 확장자**: `*.java`, `*.kt`
- **프레임워크 클래스**: `SpringFramework`

## 감지 전략

### 의존성 기반 감지

프레임워크는 빌드 파일에서 특정 의존성을 찾아 Spring 프로젝트를 감지합니다:

**필수 의존성:**
- `spring-web`
- `spring-boot`
- `springframework`

**검색 대상 매니페스트 파일:**
- `pom.xml` (Maven)
- `build.gradle` (Gradle)
- `build.gradle.kts` (Kotlin DSL)

> [!NOTE]
> Spring 감지는 의존성 기반 전략을 사용하여 Java/JVM 빌드 매니페스트 파일에서 Spring 관련 의존성을 검색합니다.


## 파싱 전략

### 어노테이션 기반 파싱

프레임워크는 어노테이션 기반 파싱을 사용하여 Spring 어노테이션에서 엔드포인트 정보를 추출합니다.

### 지원되는 어노테이션

| 어노테이션 | HTTP 메서드 | 예제 |
|------------|-------------|------|
| `@GetMapping` | GET | `@GetMapping("/users")` |
| `@PostMapping` | POST | `@PostMapping("/users")` |
| `@PutMapping` | PUT | `@PutMapping("/users/{id}")` |
| `@DeleteMapping` | DELETE | `@DeleteMapping("/users/{id}")` |
| `@PatchMapping` | PATCH | `@PatchMapping("/users/{id}")` |
| `@RequestMapping` | 다양함 | `@RequestMapping(value="/users", method=RequestMethod.GET)` |

### 경로 추출 패턴

파서는 다양한 경로 정의 형식을 인식합니다:

1. **단순 경로**: `@GetMapping("/users")`
2. **value 매개변수**: `@RequestMapping(value = "/users")`
3. **path 매개변수**: `@RequestMapping(path = "/users")`
4. **단일 따옴표**: `@GetMapping('/users')`

### 컨트롤러 기본 경로 지원

프레임워크는 컨트롤러 레벨의 `@RequestMapping` 어노테이션을 자동으로 감지하여 메서드 레벨 매핑과 결합합니다:

```java
@RestController
@RequestMapping("/api/users")  // 기본 경로
public class UserController {

    @GetMapping("/profile")     // 메서드 경로
    public User getProfile() {  // 최종 경로: /api/users/profile
        // ...
    }
}
```

> [!TIP]
> 컨트롤러 기본 경로는 자동으로 감지되어 메서드 경로와 결합됩니다.

## 설정 옵션

### 파일 처리
- **포함 패턴**: `*.java`, `*.kt`
- **제외 패턴**:
  - `**/target` (Maven 빌드 디렉토리)
  - `**/build` (Gradle 빌드 디렉토리)
  - `**/.gradle` (Gradle 캐시)

### 검색 옵션
- `--case-sensitive`: Java 어노테이션 대소문자 구분 유지
- `--type java`: Java 파일 검색 최적화
- `--type kotlin`: Kotlin 파일 검색 최적화

### 패턴 매칭
```lua
patterns = {
  GET = { "@GetMapping", "@RequestMapping.*method.*=.*GET" },
  POST = { "@PostMapping", "@RequestMapping.*method.*=.*POST" },
  PUT = { "@PutMapping", "@RequestMapping.*method.*=.*PUT" },
  DELETE = { "@DeleteMapping", "@RequestMapping.*method.*=.*DELETE" },
  PATCH = { "@PatchMapping", "@RequestMapping.*method.*=.*PATCH" },
}
```

## 메타데이터 향상

### 프레임워크별 태그
- `java` 또는 `kotlin` (언어)
- `spring` (프레임워크)

### 메타데이터 필드
- `framework_version`: "spring"
- `language`: "java" 또는 "kotlin"
- `controller_base_path`: `@RequestMapping`의 기본 경로
- `controller_name`: 컨트롤러 클래스 이름

### 신뢰도 점수
기본 신뢰도: 0.8

**신뢰도 향상:**
- +0.1 잘 형성된 경로 (`/`로 시작)
- +0.1 표준 HTTP 메서드

## 엔드포인트 구조 예제

### 기본 REST 컨트롤러
```java
@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping
    public List<User> getAllUsers() { }
    // 감지됨: GET /api/users

    @GetMapping("/{id}")
    public User getUser(@PathVariable Long id) { }
    // 감지됨: GET /api/users/{id}

    @PostMapping
    public User createUser(@RequestBody User user) { }
    // 감지됨: POST /api/users

    @PutMapping("/{id}")
    public User updateUser(@PathVariable Long id, @RequestBody User user) { }
    // 감지됨: PUT /api/users/{id}

    @DeleteMapping("/{id}")
    public void deleteUser(@PathVariable Long id) { }
    // 감지됨: DELETE /api/users/{id}
}
```

### 고급 RequestMapping
```java
@RestController
public class AdvancedController {

    @RequestMapping(value = "/search", method = RequestMethod.GET)
    public List<User> searchUsers() { }
    // 감지됨: GET /search

    @RequestMapping(path = "/batch", method = RequestMethod.POST)
    public void batchProcess() { }
    // 감지됨: POST /batch
}
```

### 고급 라우트 패턴
```java
@RestController
@RequestMapping("/api/v1")
public class ApiController {

    @GetMapping("/users/{userId}/posts/{postId}")
    public Post getUserPost(@PathVariable Long userId, @PathVariable Long postId) {
        return postService.getUserPost(userId, postId);
    }
    // 감지됨: GET /api/v1/users/{userId}/posts/{postId}

    @GetMapping("/search")
    public List<User> search(@RequestParam String q) {
        return userService.search(q);
    }
    // 감지됨: GET /api/v1/search
}
```

## 문제 해결

### 일반적인 문제

> [!WARNING]
> **엔드포인트가 감지되지 않음**
> - `pom.xml` 또는 `build.gradle`에서 Spring 의존성 확인
> - 컨트롤러 클래스가 적절한 어노테이션을 사용하는지 확인
> - 파일이 `.java` 또는 `.kt` 확장자를 가지는지 확인

> [!CAUTION]
> **잘못된 경로**
> - 컨트롤러의 `@RequestMapping` 기본 경로 확인
> - 경로 연결이 올바른지 확인

> [!TIP]
> **누락된 메서드**
> - 어노테이션이 Spring 규칙을 따르는지 확인
> - 어노테이션 이름의 오타 확인

### 디버그 정보

프레임워크 디버깅을 활성화하여 감지 및 파싱 세부사항을 확인:
```lua
-- Neovim 설정에서
vim.g.endpoint_debug = true
```

## 통합 노트

> [!INFO]
> - Spring Boot 2.x 및 3.x와 호환
> - Spring WebMVC 및 WebFlux와 호환
> - Java 및 Kotlin 코드베이스 모두 지원
> - 중첩된 경로 구조 및 경로 변수 처리
> - 빌드 디렉토리를 검색에서 자동 제외
> - 리액티브 엔드포인트 및 함수형 라우팅 지원
> - Spring Security 및 사용자 정의 필터와 호환