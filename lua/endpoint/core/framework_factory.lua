---@class endpoint.core.framework_factory_simple
local M = {}

local interface = require("endpoint.core.framework_interface")

---@type table<string, endpoint.framework_base>
local _registered_frameworks = {}

-- 프레임워크 등록
---@param name string
---@param framework endpoint.framework_base
function M.register_framework(name, framework)
  _registered_frameworks[name] = framework
end

-- 등록된 모든 프레임워크 가져오기
---@return table<string, endpoint.framework_base>
function M.get_all_frameworks()
  return _registered_frameworks
end

-- 특정 프레임워크 가져오기
---@param name string
---@return endpoint.framework_base?
function M.get_framework(name)
  return _registered_frameworks[name]
end

-- 프레임워크 감지
---@return endpoint.framework_base?, string?
function M.detect_framework()
  local detected_frameworks = {}

  for name, framework in pairs(_registered_frameworks) do
    if framework.detect and framework.detect() then
      table.insert(detected_frameworks, { name = name, framework = framework })
    end
  end

  -- 첫 번째 감지된 프레임워크 반환
  if #detected_frameworks > 0 then
    local selected = detected_frameworks[1]
    return selected.framework, selected.name
  end

  return nil, nil
end

-- 프레임워크가 포괄적 분석 방식인지 확인
---@param framework endpoint.framework_base
---@return boolean
function M.is_comprehensive_framework(framework)
  return interface.is_comprehensive_framework(framework)
end

-----------------------------------------------------------
-- 쉬운 프레임워크 생성 헬퍼들
-----------------------------------------------------------

---@class endpoint.quick_framework_config
---@field name string
---@field files? string[]
---@field dependencies? string[]
---@field file_extensions string[]
---@field patterns table<string, string[]>
---@field exclude_patterns? string[]
---@field custom_parser? fun(content: string, method: string): string?, string?

-- 5분만에 패턴 매칭 프레임워크 생성
---@param config endpoint.quick_framework_config
---@return endpoint.framework_pattern
function M.create_quick_pattern_framework(config)
  local framework_config = {
    name = config.name,
    file_extensions = config.file_extensions,
    exclude_patterns = config.exclude_patterns or {},
    search_options = {},
  }

  local detection = {
    files = config.files or {},
    dependencies = config.dependencies or {},
    content_patterns = {},
  }

  local framework = interface.create_pattern_framework(framework_config, detection, config.patterns)

  -- 커스텀 파서가 있으면 적용
  if config.custom_parser then
    function framework.parse_line(line, method)
      local file_path, line_number, column, content = line:match("([^:]+):(%d+):(%d+):(.*)")
      if not file_path or not content then
        return nil
      end

      local http_method, endpoint_path = config.custom_parser(content, method)
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
  end

  return framework
end

-- 포괄적 분석 프레임워크 생성 (Django, Rails용)
---@param config endpoint.framework_config
---@param detection endpoint.framework_detection
---@param analyzer table
---@return endpoint.framework_comprehensive
function M.create_comprehensive_framework(config, detection, analyzer)
  return interface.create_comprehensive_framework(config, detection, analyzer)
end

-- 모든 프레임워크 자동 로드
function M.load_all_frameworks()
  -- 내장 프레임워크들 로드
  local builtin_frameworks = {
    "django", "spring", "dotnet", "ktor", "nestjs",
    "express", "fastapi", "rails", "symfony", "servlet", "react_router"
  }

  for _, name in ipairs(builtin_frameworks) do
    local success, framework_module = pcall(require, "endpoint.frameworks." .. name)
    if success and framework_module then
      M.register_framework(name, framework_module)
    end
  end

  -- 사용자 정의 프레임워크들도 자동 로드 (확장 가능)
  local user_frameworks_path = vim.fn.stdpath("config") .. "/lua/endpoint/frameworks"
  if vim.fn.isdirectory(user_frameworks_path) == 1 then
    local user_frameworks = vim.fn.glob(user_frameworks_path .. "/*.lua", false, true)
    for _, file_path in ipairs(user_frameworks) do
      local name = vim.fn.fnamemodify(file_path, ":t:r")
      local success, framework_module = pcall(dofile, file_path)
      if success and framework_module then
        M.register_framework(name, framework_module)
      end
    end
  end
end

-- 런타임에서 간단한 프레임워크 등록
---@param name string
---@param patterns table<string, string[]>
---@param opts? table
function M.quick_register(name, patterns, opts)
  opts = opts or {}

  local framework = M.create_quick_pattern_framework({
    name = name,
    file_extensions = opts.file_extensions or {"*.*"},
    patterns = patterns,
    files = opts.files,
    dependencies = opts.dependencies,
    exclude_patterns = opts.exclude_patterns,
    custom_parser = opts.custom_parser,
  })

  M.register_framework(name, framework)
  return framework
end

return M