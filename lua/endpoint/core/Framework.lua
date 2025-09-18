---@class endpoint.Framework
local Framework = {}
Framework.__index = Framework

local log = require "endpoint.utils.log"

---Creates a new Framework instance
function Framework:new(name, config)
  local instance = setmetatable({}, self)
  instance.name = name
  instance.config = config or {}
  instance:_validate_config()
  instance:_initialize()
  return instance
end

---Validates the framework configuration
function Framework:_validate_config()
  if not self.name then
    error "Framework name is required"
  end

  if not self.config.file_extensions then
    self.config.file_extensions = { "*.*" }
  end

  if not self.config.exclude_patterns then
    self.config.exclude_patterns = {}
  end
end

---Sets up detection and parsing components
function Framework:_initialize()
  -- Will be overridden by subclasses
end

---Detects if this framework is present in the current project
function Framework:detect()
  error("detect() must be implemented by subclass: " .. self.name)
end

---Parses content to extract endpoint information
function Framework:parse(content, file_path, line_number, column)
  error("parse() must be implemented by subclass: " .. self.name)
  -- Suppress unused warnings
  ---@diagnostic disable-next-line: unused-local
  local _ = content
  ---@diagnostic disable-next-line: unused-local
  _ = file_path
  ---@diagnostic disable-next-line: unused-local
  _ = line_number
  ---@diagnostic disable-next-line: unused-local
  _ = column
end

---Gets the search command for finding all endpoints
function Framework:get_search_cmd()
  if not self.config.patterns then
    error("Patterns not configured for framework: " .. self.name)
  end

  local rg = require "endpoint.utils.rg"

  -- Create search options for all patterns
  local search_options = {
    method_patterns = self.config.patterns,
    file_globs = self.config.file_extensions,
    exclude_globs = self.config.exclude_patterns,
    extra_flags = self.config.search_options or {},
  }

  return rg.create_command(search_options)
end

---Main template method for scanning endpoints
function Framework:scan(options)
  options = options or {}

  log.framework_debug("Starting scan with framework: " .. self.name)

  if not self:detect() then
    log.framework_debug("Framework not detected: " .. self.name)
    return {}
  end

  -- Perform single comprehensive search for all patterns
  local discovered_endpoints = self:_perform_comprehensive_scan(options)

  -- Post-process endpoints (remove duplicates, etc.)
  discovered_endpoints = self:_post_process_endpoints(discovered_endpoints)

  log.framework_debug(string.format("Found %d endpoints with %s", #discovered_endpoints, self.name))

  return discovered_endpoints
end

---Performs comprehensive scan for all endpoint patterns
function Framework:_perform_comprehensive_scan(scan_options)
  local search_command = self:get_search_cmd()
  -- Suppress unused warning
  ---@diagnostic disable-next-line: unused-local
  local _ = scan_options

  log.framework_debug("Executing comprehensive search: " .. search_command)

  local search_result = vim.fn.system(search_command)
  if vim.v.shell_error ~= 0 then
    log.framework_debug("Search command failed: " .. search_result)
    return {}
  end

  local found_endpoints = {}
  local result_lines = vim.split(search_result, "\n", { trimempty = true })

  for _, result_line in ipairs(result_lines) do
    local parsed_endpoint = self:_parse_search_result_line(result_line)
    if parsed_endpoint then
      table.insert(found_endpoints, parsed_endpoint)
    end
  end

  return found_endpoints
end

---Parses a single ripgrep search result line
function Framework:_parse_search_result_line(search_result_line)
  if not search_result_line or search_result_line == "" then
    return nil
  end

  -- Parse ripgrep output format: file:line:col:content
  local source_file_path, source_line_number, source_column_position, line_content =
    search_result_line:match "([^:]+):(%d+):(%d+):(.*)"
  if not source_file_path or not source_line_number or not source_column_position or not line_content then
    return nil
  end

  -- Use the concrete implementation's parse method
  local line_num = tonumber(source_line_number) or 1
  local col_pos = tonumber(source_column_position) or 1
  local parsed_endpoint = self:parse(line_content, source_file_path, line_num, col_pos)

  if parsed_endpoint then
    -- Ensure required fields are set
    parsed_endpoint.framework = self.name
    parsed_endpoint.file_path = parsed_endpoint.file_path or source_file_path
    parsed_endpoint.line_number = parsed_endpoint.line_number or line_num
    parsed_endpoint.column = parsed_endpoint.column or col_pos

    -- Generate display value if not provided
    if not parsed_endpoint.display_value and parsed_endpoint.method and parsed_endpoint.endpoint_path then
      parsed_endpoint.display_value = parsed_endpoint.method .. " " .. parsed_endpoint.endpoint_path
    end
  end

  return parsed_endpoint
end

---Post-processes endpoints to remove duplicates and clean up
function Framework:_post_process_endpoints(endpoints)
  -- Remove duplicates based on method + path + file + line
  local seen = {}
  local unique_endpoints = {}

  for _, endpoint in ipairs(endpoints) do
    local key = string.format(
      "%s:%s:%s:%d",
      endpoint.method or "",
      endpoint.endpoint_path or "",
      endpoint.file_path or "",
      endpoint.line_number or 0
    )

    if not seen[key] then
      seen[key] = true
      table.insert(unique_endpoints, endpoint)
    end
  end

  return unique_endpoints
end

---Gets the framework name
function Framework:get_name()
  return self.name
end

---Gets the framework configuration
function Framework:get_config()
  return vim.deepcopy(self.config)
end

---Checks if this instance is of a specific framework type
function Framework:is_instance_of(framework_class)
  local mt = getmetatable(self)
  while mt do
    if mt == framework_class then
      return true
    end
    mt = getmetatable(mt)
  end
  return false
end

return Framework

