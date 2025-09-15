-- Framework Creation Guide Examples
-- 이 파일은 새로운 프레임워크를 쉽게 추가하는 방법을 보여줍니다.

local templates = require("endpoint.core.framework_templates")
local factory = require("endpoint.core.framework_factory")
local strategies = require("endpoint.core.strategies")

-----------------------------------------------------------
-- 예시 1: Laravel 프레임워크 추가 (패턴 매칭 방식)
-----------------------------------------------------------

local laravel_config = {
  framework_name = "laravel",
  language = "php",
  strategy = strategies.STRATEGY_TYPES.PATTERN_MATCHING,
  file_extensions = { "*.php" },
  route_patterns = {
    GET = { "Route::get\\(", "->get\\(" },
    POST = { "Route::post\\(", "->post\\(" },
    PUT = { "Route::put\\(", "->put\\(" },
    DELETE = { "Route::delete\\(", "->delete\\(" },
    PATCH = { "Route::patch\\(", "->patch\\(" },
    ALL = {
      "Route::get\\(",
      "Route::post\\(",
      "Route::put\\(",
      "Route::delete\\(",
      "Route::patch\\(",
      "->get\\(",
      "->post\\(",
      "->put\\(",
      "->delete\\(",
      "->patch\\(",
    },
  },
  detection_files = { "artisan", "composer.json" },
  dependencies = { "laravel/framework", "laravel" },
  exclude_dirs = { "vendor", "storage", "bootstrap/cache" },
}

-----------------------------------------------------------
-- 예시 2: Gin 프레임워크 추가 (하이브리드 방식)
-----------------------------------------------------------

local gin_config = {
  framework_name = "gin",
  language = "go",
  strategy = strategies.STRATEGY_TYPES.HYBRID,
  file_extensions = { "*.go" },
  route_patterns = {
    GET = { "\\.GET\\(", "router\\.GET\\(" },
    POST = { "\\.POST\\(", "router\\.POST\\(" },
    PUT = { "\\.PUT\\(", "router\\.PUT\\(" },
    DELETE = { "\\.DELETE\\(", "router\\.DELETE\\(" },
    PATCH = { "\\.PATCH\\(", "router\\.PATCH\\(" },
    ALL = {
      "\\.GET\\(",
      "\\.POST\\(",
      "\\.PUT\\(",
      "\\.DELETE\\(",
      "\\.PATCH\\(",
      "router\\.GET\\(",
      "router\\.POST\\(",
      "router\\.PUT\\(",
      "router\\.DELETE\\(",
      "router\\.PATCH\\(",
    },
  },
  detection_files = { "go.mod" },
  dependencies = { "github.com/gin-gonic/gin" },
  exclude_dirs = { "vendor" },
}

-----------------------------------------------------------
-- 예시 3: Actix Web 프레임워크 추가 (패턴 매칭 방식)
-----------------------------------------------------------

local actix_config = {
  framework_name = "actix_web",
  language = "rust",
  strategy = strategies.STRATEGY_TYPES.PATTERN_MATCHING,
  file_extensions = { "*.rs" },
  route_patterns = {
    GET = { "web::get\\(\\)", "#\\[get\\(", "\\.route\\(.*web::get\\(\\)" },
    POST = { "web::post\\(\\)", "#\\[post\\(", "\\.route\\(.*web::post\\(\\)" },
    PUT = { "web::put\\(\\)", "#\\[put\\(", "\\.route\\(.*web::put\\(\\)" },
    DELETE = { "web::delete\\(\\)", "#\\[delete\\(", "\\.route\\(.*web::delete\\(\\)" },
    PATCH = { "web::patch\\(\\)", "#\\[patch\\(", "\\.route\\(.*web::patch\\(\\)" },
    ALL = {
      "web::get\\(\\)",
      "web::post\\(\\)",
      "web::put\\(\\)",
      "web::delete\\(\\)",
      "web::patch\\(\\)",
      "#\\[get\\(",
      "#\\[post\\(",
      "#\\[put\\(",
      "#\\[delete\\(",
      "#\\[patch\\(",
    },
  },
  detection_files = { "Cargo.toml" },
  dependencies = { "actix-web" },
  exclude_dirs = { "target" },
}

-----------------------------------------------------------
-- 실제 프레임워크 생성 예시
-----------------------------------------------------------

-- 방법 1: 템플릿 코드만 생성 (수동으로 추가 편집 필요)
local function create_laravel_template()
  local template_code = templates.generate_framework_template(laravel_config)
  print("Generated Laravel template:")
  print(template_code)
end

-- 방법 2: 파일로 직접 생성 (바로 사용 가능한 기본 구조)
local function create_gin_framework_file()
  templates.create_framework_file(gin_config, "/path/to/gin.lua")
end

-- 방법 3: 런타임에 프레임워크 등록 (테스트용)
local function register_actix_framework()
  local actix_framework = factory.create_quick_pattern_framework({
    name = actix_config.framework_name,
    files = actix_config.detection_files,
    dependencies = actix_config.dependencies,
    file_extensions = actix_config.file_extensions,
    patterns = actix_config.route_patterns,
    exclude_patterns = actix_config.exclude_dirs,
  })

  factory.register_framework("actix_web", actix_framework)
end

-----------------------------------------------------------
-- 즉석에서 간단한 프레임워크 추가하기
-----------------------------------------------------------

local function add_simple_framework()
  -- 5분만에 새 프레임워크 추가하는 예시
  local simple_framework = factory.create_quick_pattern_framework({
    name = "my_custom_framework",
    files = { "framework.config" },
    dependencies = { "my-framework" },
    file_extensions = { "*.js", "*.ts" },
    patterns = {
      GET = { "app\\.get\\(" },
      POST = { "app\\.post\\(" },
      ALL = { "app\\.(get|post|put|delete)\\(" },
    },
  })

  -- 커스텀 parse_line 로직 추가
  function simple_framework.parse_line(line, method)
    local file_path, line_number, column, content = line:match("([^:]+):(%d+):(%d+):(.*)")
    if not content then return nil end

    -- app.get('/users', handler) 패턴 파싱
    local http_method, path = content:match("app%.(%w+)%(.-['\"]([^'\"]+)['\"]")
    if http_method and path then
      return {
        method = http_method:upper(),
        endpoint_path = path,
        file_path = file_path,
        line_number = tonumber(line_number),
        column = tonumber(column),
        display_value = http_method:upper() .. " " .. path,
      }
    end

    return nil
  end

  factory.register_framework("my_custom_framework", simple_framework)
  print("Custom framework registered successfully!")
end

-----------------------------------------------------------
-- 사용 방법 요약
-----------------------------------------------------------

--[[

🚀 새 프레임워크 추가 방법:

1. **5분 Quick Setup** (간단한 프레임워크):
   ```lua
   local framework = factory.create_quick_pattern_framework({
     name = "framework_name",
     file_extensions = {"*.ext"},
     patterns = { GET = {"pattern"}, ... },
     -- ... other config
   })
   factory.register_framework("framework_name", framework)
   ```

2. **Template Generator** (표준 구조):
   ```lua
   local config = { framework_name = "name", ... }
   templates.create_framework_file(config)
   -- 생성된 파일을 편집하여 구체적인 로직 구현
   ```

3. **Full Custom** (복잡한 프레임워크):
   ```lua
   -- interface.create_comprehensive_framework() 사용
   -- 또는 완전히 커스텀 구현
   ```

📋 체크리스트:
- [ ] 프레임워크 감지 로직
- [ ] 검색 패턴 정의
- [ ] 라인 파싱 로직
- [ ] 전략 선택 (PATTERN_MATCHING | COMPREHENSIVE | HYBRID)
- [ ] 테스트 케이스 작성

--]]

-- 실제 사용 예시들을 실행하려면 아래 주석을 해제하세요:
-- create_laravel_template()
-- register_actix_framework()
-- add_simple_framework()

return {
  laravel_config = laravel_config,
  gin_config = gin_config,
  actix_config = actix_config,
  create_laravel_template = create_laravel_template,
  create_gin_framework_file = create_gin_framework_file,
  register_actix_framework = register_actix_framework,
  add_simple_framework = add_simple_framework,
}