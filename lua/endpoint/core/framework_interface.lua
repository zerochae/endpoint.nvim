---@class endpoint.core.framework_interface_simple
local M = {}

---@class endpoint.framework_config
---@field name string Framework name
---@field file_extensions string[] File extensions to search
---@field exclude_patterns string[] Patterns to exclude from search
---@field search_options string[] Additional search options

---@class endpoint.framework_detection
---@field files string[] Required files for detection
---@field dependencies string[] Dependencies to look for
---@field content_patterns string[] Code patterns that indicate framework usage
---@field custom_detector? fun(): boolean Custom detection function

---@class endpoint.framework_base
---@field config endpoint.framework_config
---@field detection endpoint.framework_detection
---@field detect fun(): boolean

-- 패턴 매칭 방식 프레임워크 (대부분의 프레임워크)
---@class endpoint.framework_pattern : endpoint.framework_base
---@field patterns table<string, string[]> Method to patterns mapping
---@field get_search_cmd fun(method: string): string
---@field parse_line fun(line: string, method: string): endpoint.entry?

-- 포괄적 분석 방식 프레임워크 (Django, Rails 같은 복잡한 구조)
---@class endpoint.framework_comprehensive : endpoint.framework_base
---@field discover_all_endpoints fun(): endpoint.entry[]
---@field get_all_endpoints_for_method fun(method: string): endpoint.entry[]

-- 프레임워크가 어떤 방식인지 판단
---@param framework endpoint.framework_base
---@return boolean is_comprehensive
function M.is_comprehensive_framework(framework)
  return framework.discover_all_endpoints ~= nil
end

-- 기본 프레임워크 생성
---@param config endpoint.framework_config
---@param detection endpoint.framework_detection
---@return endpoint.framework_base
function M.create_base_framework(config, detection)
  local framework = {
    config = config,
    detection = detection,
  }

  -- 기본 detection 메서드
  function framework.detect()
    local fs = require("endpoint.utils.fs")

    -- 파일 존재 확인
    if detection.files then
      local found_file = false
      for _, file in ipairs(detection.files) do
        if fs.has_file({ file }) then
          found_file = true
          break
        end
      end
      if not found_file then
        return false
      end
    end

    -- 의존성 확인
    if detection.dependencies then
      local found_dep = false
      for _, dep in ipairs(detection.dependencies) do
        if fs.file_contains("package.json", dep)
            or fs.file_contains("pom.xml", dep)
            or fs.file_contains("build.gradle", dep)
            or fs.file_contains("requirements.txt", dep)
            or fs.file_contains("Cargo.toml", dep)
            or fs.file_contains("composer.json", dep) then
          found_dep = true
          break
        end
      end
      if not found_dep then
        return false
      end
    end

    -- 커스텀 감지 함수
    if detection.custom_detector then
      return detection.custom_detector()
    end

    return true
  end

  return framework
end

-- 패턴 매칭 프레임워크 생성 (대부분의 프레임워크용)
---@param config endpoint.framework_config
---@param detection endpoint.framework_detection
---@param patterns table<string, string[]>
---@return endpoint.framework_pattern
function M.create_pattern_framework(config, detection, patterns)
  local framework = M.create_base_framework(config, detection)
  framework.patterns = patterns

  -- 검색 명령 생성
  local search_utils = require("endpoint.utils.search")
  local get_search_cmd = search_utils.create_search_cmd_generator(
    patterns,
    config.file_extensions,
    config.exclude_patterns or {},
    config.search_options or {}
  )

  function framework.get_search_cmd(method)
    return get_search_cmd(method)
  end

  -- 기본 parse_line 구현 (오버라이드 가능)
  function framework.parse_line(line, method)
    local file_path, line_number, column, content = line:match("([^:]+):(%d+):(%d+):(.*)")
    if not file_path or not content then
      return nil
    end

    -- 기본적인 파싱 로직 (프레임워크별로 오버라이드 권장)
    local http_method, endpoint_path = M.extract_basic_route_info(content, method)
    if not http_method or not endpoint_path then
      return nil
    end

    return {
      method = http_method,
      endpoint_path = endpoint_path,
      file_path = file_path,
      line_number = tonumber(line_number),
      column = tonumber(column),
      display_value = http_method .. " " .. endpoint_path,
    }
  end

  return framework
end

-- 포괄적 분석 프레임워크 생성 (Django, Rails용)
---@param config endpoint.framework_config
---@param detection endpoint.framework_detection
---@param analyzer table Analysis methods
---@return endpoint.framework_comprehensive
function M.create_comprehensive_framework(config, detection, analyzer)
  local framework = M.create_base_framework(config, detection)

  framework.discover_all_endpoints = analyzer.discover_all_endpoints
  framework.get_all_endpoints_for_method = analyzer.get_all_endpoints_for_method

  -- 포괄적 분석용 검색 명령
  function framework.get_search_cmd(method)
    if method == "ALL" then
      return analyzer.get_discovery_search_cmd and analyzer.get_discovery_search_cmd() or "echo '# Comprehensive analysis'"
    else
      return "echo '# Using cached comprehensive analysis for " .. method .. "'"
    end
  end

  -- 포괄적 분석에서는 parse_line이 다르게 작동
  function framework.parse_line(line, method)
    return analyzer.parse_line and analyzer.parse_line(line, method) or nil
  end

  return framework
end

-- 기본 라우트 정보 추출 (간단한 패턴용)
---@param content string
---@param search_method string
---@return string?, string?
function M.extract_basic_route_info(content, search_method)
  -- 매우 기본적인 패턴들 (각 프레임워크에서 오버라이드 권장)

  -- Pattern 1: method('/path')
  local method, path = content:match("(%w+)%(['\"]([^'\"]+)['\"]")
  if method and path then
    return method:upper(), path
  end

  -- Pattern 2: @method('/path') 또는 @Route('/path', method='GET')
  path = content:match("@%w+%(['\"]([^'\"]+)['\"]")
  if path then
    return search_method and search_method:upper() or "GET", path
  end

  return nil, nil
end

return M