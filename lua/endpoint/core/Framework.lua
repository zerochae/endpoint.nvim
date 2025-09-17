---@class Framework
---@field protected name string
---@field protected config table
---@field protected detection_strategy any
---@field protected parsing_strategy any
local Framework = {}
Framework.__index = Framework

local log = require "endpoint.utils.log"

---Creates a new Framework instance
---@param name string Framework name
---@param config? table Framework configuration
---@return Framework
function Framework:new(name, config)
  local instance = setmetatable({}, self)
  instance.name = name
  instance.config = config or {}
  instance:_validate_config()
  instance:_setup_strategies()
  return instance
end

---Validates the framework configuration
---@protected
function Framework:_validate_config()
  if not self.name then
    error("Framework name is required")
  end

  if not self.config.file_extensions then
    self.config.file_extensions = { "*.*" }
  end

  if not self.config.exclude_patterns then
    self.config.exclude_patterns = {}
  end
end

---Sets up detection and parsing strategies
---@protected
function Framework:_setup_strategies()
  -- Will be overridden by subclasses
end

---Detects if this framework is present in the current project
---@abstract
---@return boolean
function Framework:detect()
  error("detect() must be implemented by subclass: " .. self.name)
end

---Parses content to extract endpoint information
---@abstract
---@param content string The content to parse
---@param file_path string Path to the file
---@param line_number number Line number in the file
---@param column number Column number in the line
---@return endpoint.entry|nil
function Framework:parse(content, file_path, line_number, column)
  error("parse() must be implemented by subclass: " .. self.name)
end

---Gets the search command for finding all endpoints
---@return string search_command The ripgrep command to find all endpoints
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
    extra_flags = self.config.search_options or {}
  }

  return rg.create_command(search_options)
end

---Main template method for scanning endpoints
---@param options? table Scan options
---@return endpoint.entry[] discovered_endpoints List of discovered endpoints
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
---@protected
---@param scan_options table Scan options
---@return endpoint.entry[] found_endpoints List of found endpoints
function Framework:_perform_comprehensive_scan(scan_options)
  local search_command = self:get_search_cmd()

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
---@protected
---@param search_result_line string Ripgrep output line
---@return endpoint.entry|nil parsed_endpoint The parsed endpoint or nil if parsing failed
function Framework:_parse_search_result_line(search_result_line)
  if not search_result_line or search_result_line == "" then
    return nil
  end

  -- Parse ripgrep output format: file:line:col:content
  local source_file_path, source_line_number, source_column_position, line_content = search_result_line:match "([^:]+):(%d+):(%d+):(.*)"
  if not source_file_path or not source_line_number or not source_column_position or not line_content then
    return nil
  end

  -- Use the concrete implementation's parse method
  local parsed_endpoint = self:parse(line_content, source_file_path, tonumber(source_line_number), tonumber(source_column_position))

  if parsed_endpoint then
    -- Ensure required fields are set
    parsed_endpoint.framework = self.name
    parsed_endpoint.file_path = parsed_endpoint.file_path or source_file_path
    parsed_endpoint.line_number = parsed_endpoint.line_number or tonumber(source_line_number)
    parsed_endpoint.column = parsed_endpoint.column or tonumber(source_column_position)

    -- Generate display value if not provided
    if not parsed_endpoint.display_value and parsed_endpoint.method and parsed_endpoint.endpoint_path then
      parsed_endpoint.display_value = parsed_endpoint.method .. " " .. parsed_endpoint.endpoint_path
    end
  end

  return parsed_endpoint
end


---Post-processes endpoints to remove duplicates and clean up
---@protected
---@param endpoints endpoint.entry[]
---@return endpoint.entry[]
function Framework:_post_process_endpoints(endpoints)
  -- Remove duplicates based on method + path + file + line
  local seen = {}
  local unique_endpoints = {}

  for _, endpoint in ipairs(endpoints) do
    local key = string.format("%s:%s:%s:%d",
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
---@return string
function Framework:get_name()
  return self.name
end

---Gets the framework configuration
---@return table
function Framework:get_config()
  return vim.deepcopy(self.config)
end

---Checks if this instance is of a specific framework type
---@param framework_class table The framework class to check against
---@return boolean
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