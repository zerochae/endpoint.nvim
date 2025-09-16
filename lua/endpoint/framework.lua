---@class endpoint.core.framework_factory
local M = {}

local log = require "endpoint.utils.log"

---@class endpoint.framework_config
---@field name string Framework name
---@field file_extensions string[] File extensions to search (e.g., {"*.java", "*.kt"})
---@field exclude_patterns? string[] Patterns to exclude from search (e.g., {"**/target/**"})
---@field search_options? string[] Additional ripgrep options

---@class endpoint.framework_detection
---@field files? string[] Required files for detection (e.g., {"pom.xml", "build.gradle"})
---@field dependencies? string[] Dependencies to look for (e.g., {"spring-boot", "spring-web"})
---@field manifest_files? string[] Dependency manifest files to search in (e.g., {"build.gradle", "pom.xml"})
---@field imports? string[] Import keywords that indicate framework usage
---@field custom_detector? fun(): boolean Custom detection function

---@alias endpoint.framework_pattern_parser fun(content: string, file_path: string, line_number: number, column: number, framework_opts: any): endpoint.entry|nil
---@alias endpoint.framework_structure_parser fun(content: string[], file_path: string, framework_opts: any): endpoint.entry[]

---@class endpoint.framework_base
---@field name string Framework name
---@field file_extensions string[] File extensions to search
---@field exclude_patterns? string[] Patterns to exclude from search
---@field detection endpoint.framework_detection Detection configuration
---@field patterns table<string, string[]> HTTP method to search patterns mapping
---@field parser endpoint.framework_pattern_parser|endpoint.framework_structure_parser Function to parse matched lines/files into endpoints
---@field detect fun(): boolean Detection function (auto-generated if not provided)
---@field get_endpoints fun(): endpoint.entry[] Main endpoint discovery function
---@field setup fun(self: endpoint.framework_base, config: table): endpoint.framework_base Setup method

---@type table<string, endpoint.framework_base>
local _registered_frameworks = {}

-- 프레임워크 등록
---@param name string
---@param framework endpoint.framework_base
function M:register_framework(name, framework)
  if _registered_frameworks[name] then
    log.framework_debug(string.format("Framework '%s' already registered, replacing...", name))
  end
  _registered_frameworks[name] = framework
end

-- 특정 프레임워크 가져오기
---@param name string
---@return endpoint.framework_base?
function M:get_framework(name)
  return _registered_frameworks[name]
end

-- 프레임워크 감지
---@return endpoint.framework_base?, string?
function M:detect_framework()
  local detected_frameworks = {}

  local framework_count = 0
  for _ in pairs(_registered_frameworks) do framework_count = framework_count + 1 end
  log.framework_debug("Checking " .. framework_count .. " registered frameworks")

  for name, framework in pairs(_registered_frameworks) do
    log.framework_debug("Testing framework: " .. name)

    if framework.detect and framework.detect() then
      log.framework_debug("Framework detected: " .. name)
      table.insert(detected_frameworks, { name = name, framework = framework })
    end
  end

  -- 첫 번째 감지된 프레임워크 반환
  if #detected_frameworks > 0 then
    local selected = detected_frameworks[1]
    return selected.framework, selected.name
  end

  log.framework_debug("No frameworks detected")

  return nil, nil
end

-- 프레임워크 스캔 (메인 진입점)
---@param options? table
---@return endpoint.entry[]
function M:scan(options)
  options = options or {}
  local cache = require "endpoint.cache"

  -- Check cache first (unless force refresh)
  if not options.force_refresh and cache.is_valid() then
    log.info("🚀 Using cached endpoints")
    return cache.get_endpoints()
  end

  log.info("🔍 Scanning for endpoints...")

  -- Detect framework
  log.framework_debug("Starting framework detection...")

  local framework, framework_name = M:detect_framework()
  if not framework then
    log.endpoint("No supported framework detected", vim.log.levels.WARN)
    return {}
  end

  local analysis_type = framework.get_endpoints and "framework-discovery" or "pattern-matching"
  log.framework_debug(string.format("Detected framework: %s (type: %s)", framework_name, analysis_type))

  local endpoints = framework.get_endpoints()

  -- Save to cache
  cache.save_endpoints(endpoints)

  log.info(string.format("🔍 Framework discovery: %d endpoints found and cached", #endpoints))

  return endpoints and endpoints or {}
end

-- 기본 프레임워크 생성
---@param name string
---@return endpoint.framework_base
function M:create_base_framework(name)
  local framework = {
    name = name,
    config = {},
    detection = {},
  }

  -- 기본 detection 메서드
  function framework.detect()
    local fs = require "endpoint.utils.fs"

    log.framework_debug("Detecting framework: " .. framework.name)

    -- 파일 존재 확인
    local has_required_files = true
    if framework.detection.files then
      local found_file = false
      for _, file in ipairs(framework.detection.files) do
        log.framework_debug("Checking file: " .. file)
        if fs.has_file(file) then
          found_file = true
          log.framework_debug("Found file: " .. file)
          break
        end
      end
      has_required_files = found_file
      if not found_file then
        log.framework_debug("No required files found for " .. framework.name)
      end
    end

    -- 의존성 확인 (선택적)
    local has_required_deps = true
    if framework.detection.dependencies and framework.detection.manifest_files then
      local found_dep = false
      for _, dep in ipairs(framework.detection.dependencies) do
        for _, manifest_file in ipairs(framework.detection.manifest_files) do
          log.framework_debug("Checking dependency '" .. dep .. "' in " .. manifest_file)
          if fs.file_contains(manifest_file, dep) then
            found_dep = true
            log.framework_debug("Found dependency: " .. dep .. " in " .. manifest_file)
            break
          end
        end
        if found_dep then
          break
        end
      end
      has_required_deps = found_dep
      if not found_dep then
        log.framework_debug("No required dependencies found for " .. framework.name)
      end
    end

    -- 커스텀 감지 함수
    if framework.detection.custom_detector then
      return framework.detection.custom_detector()
    end

    -- 파일 존재 OR 의존성 확인 중 하나라도 성공하면 감지
    local detected = has_required_files or has_required_deps

    log.framework_debug("Framework " .. framework.name .. " detection result: " .. tostring(detected))

    return detected
  end

  return framework
end

-- 기본 라우트 정보 추출
---@param content string
---@return string?, string?
function M:extract_basic_route_info(content)
  -- Pattern 1: method('/path')
  local method, path = content:match "(%w+)%(['\"]([^'\"]+)['\"]"
  if method and path then
    return method:upper(), path
  end

  -- Pattern 2: @method('/path')
  path = content:match "@%w+%(['\"]([^'\"]+)['\"]"
  if path then
    return "GET", path
  end

  return nil, nil
end

-----------------------------------------------------------
-- 프레임워크 생성
-----------------------------------------------------------

---@class endpoint.framework_create_config
---@field name string Framework name
---@field file_extensions string[] File extensions to search
---@field exclude_patterns? string[] Patterns to exclude from search
---@field detection endpoint.framework_detection Detection configuration
---@field patterns table<string, string[]> HTTP method to search patterns mapping
---@field parser endpoint.framework_pattern_parser|endpoint.framework_structure_parser Function to parse matched lines/files into endpoints
---@field search_options? string[] Additional ripgrep options

-- Pattern-based 스캔 방법 (Spring, Express, FastAPI, Ktor 등)
---@param framework_opts endpoint.framework_base Framework options
---@param scan_config table Scan configuration
---@return fun(): endpoint.entry[] Scanner function
local function create_pattern_based_scanner(framework_opts, scan_config)
  local search_utils = require "endpoint.utils.search"

  return function()
    local cmd = search_utils.create_search_cmd_generator({
      method_patterns = scan_config.patterns,
      file_globs = framework_opts.file_extensions,
      exclude_globs = framework_opts.exclude_patterns,
      extra_flags = scan_config.search_options,
    })

    if cmd == "" then
      return {}
    end

    local output = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error

    if exit_code ~= 0 then
      return {}
    end

    local endpoints = {}
    for line in vim.gsplit(output, "\n") do
      if line ~= "" then
        local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
        if file_path and content and line_number and column then
          local line_num = tonumber(line_number)
          local col_num = tonumber(column)
          if line_num and col_num then
            local parsed_endpoint = scan_config.parser(content, file_path, line_num, col_num, framework_opts)

            if parsed_endpoint then
              table.insert(endpoints, parsed_endpoint)
            end
          end
        end
      end
    end

    return endpoints
  end
end

-- Structure 기반 스캔 방법 (Django, Rails 등)
---@param framework_opts endpoint.framework_base Framework options
---@param scan_config table Scan configuration
---@return fun(): endpoint.entry[] Scanner function
local function create_structure_based_scanner(framework_opts, scan_config)
  return function()
    local endpoints = {}

    for _, file_pattern in ipairs(scan_config.target_files or {}) do
      local files = vim.fn.glob(file_pattern, false, true)
      for _, file_path in ipairs(files) do
        if vim.fn.filereadable(file_path) == 1 then
          local content = vim.fn.readfile(file_path)
          local parsed_endpoints = scan_config.parser(content, file_path, framework_opts)

          if parsed_endpoints then
            vim.list_extend(endpoints, parsed_endpoints)
          end
        end
      end
    end

    return endpoints
  end
end

---@param name string Framework name
---@return endpoint.framework_base
function M:new(name)
  local framework = M:create_base_framework(name)

  function framework:setup(config)
    -- 기본 설정이면 업데이트
    if config.file_extensions or config.exclude_patterns or config.detection then
      self.file_extensions = config.file_extensions or self.file_extensions or {}
      self.exclude_patterns = config.exclude_patterns or self.exclude_patterns or {}
      self.detection = config.detection or self.detection or {}
    end

    if config.type then
      if config.type == "pattern" then
        self.get_endpoints = create_pattern_based_scanner(self, config)
      elseif config.type == "structure" then
        self.get_endpoints = create_structure_based_scanner(self, config)
      else
        error("Unknown scan type: " .. tostring(config.type))
      end
    end

    return self
  end

  return framework
end

-- 프레임워크들을 디렉토리에서 자동으로 스캔하여 등록
function M:register_frameworks()
  local frameworks_path = debug.getinfo(1, "S").source:sub(2):match "(.*/)"
  frameworks_path = frameworks_path:gsub("/framework%.lua", "/")

  log.framework_debug("Scanning frameworks from: " .. frameworks_path .. "frameworks/")

  -- 1. 디렉토리 구조 스캔
  local framework_dirs = vim.fn.glob(frameworks_path .. "frameworks/*/", false, true)

  log.framework_debug("Found " .. #framework_dirs .. " framework directories")

  for _, dir in ipairs(framework_dirs) do
    local framework_name = vim.fn.fnamemodify(dir:sub(1, -2), ":t")
    local init_path = dir .. "init.lua"

    log.framework_debug("Checking framework: " .. framework_name .. " at " .. init_path)

    if vim.fn.filereadable(init_path) == 1 then
      -- require로 로드 (내부 모듈 참조 가능)
      local success, framework_module = pcall(require, "endpoint.frameworks." .. framework_name)
      if success and framework_module then
        M:register_framework(framework_name, framework_module)
        log.framework_debug("Successfully registered: " .. framework_name)
      else
        log.framework_debug("Failed to load framework: " .. framework_name .. " - " .. tostring(framework_module))
      end
    else
      log.framework_debug("init.lua not found for: " .. framework_name)
    end
  end

  -- 2. 파일 구조 스캔 (backward compatibility)
  local framework_files = vim.fn.glob(frameworks_path .. "frameworks/*.lua", false, true)

  for _, file_path in ipairs(framework_files) do
    local framework_name = vim.fn.fnamemodify(file_path, ":t:r")

    if vim.fn.filereadable(file_path) == 1 then
      -- require로 로드
      local success, framework_module = pcall(require, "endpoint.frameworks." .. framework_name)
      if success and framework_module then
        M:register_framework(framework_name, framework_module)
      else
        log.framework_debug("Failed to load framework: " .. framework_name)
      end
    end
  end
end

return M
