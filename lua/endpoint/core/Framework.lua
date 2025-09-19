---@class endpoint.Framework
local Framework = {}
Framework.__index = Framework

local log = require "endpoint.utils.log"

---Creates a new Framework instance
function Framework:new(name, config)
  local framework = setmetatable({}, self)
  framework.name = name
  framework.config = config or {}
  framework:_validate_config()
  framework:_setup_detector_and_parser()
  return framework
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

---Sets up detector and parser based on configuration
function Framework:_setup_detector_and_parser()
  if self.config.detector then
    local Detector = require "endpoint.core.Detector"
    self.detector = Detector:new_dependency_detector(
      self.config.detector.dependencies or {},
      self.config.detector.manifest_files or {},
      self.config.detector.name or (self.name .. "_detection")
    )
  end

  if self.config.parser then
    self.parser = self.config.parser:new()
  end
end

---Detects if this framework is present in the current project (unified implementation)
function Framework:detect()
  if not self.detector then
    self:_initialize()
  end
  if self.detector then
    return self.detector:is_target_detected()
  end
  return false
end

---Parses content to extract endpoint information (unified implementation)
function Framework:parse(content, file_path, line_number, column)
  -- Ensure parser is initialized
  if not self.parser then
    self:_initialize()
  end

  if not self.parser then
    return nil
  end

  local parsed_result = self.parser:parse_content(content, file_path, line_number, column)

  -- Handle both single endpoint and array of endpoints
  if parsed_result then
    if type(parsed_result) == "table" and #parsed_result > 0 then
      -- Array of endpoints
      for _, endpoint in ipairs(parsed_result) do
        endpoint.framework = self.name
        self:_enhance_endpoint(endpoint, file_path)
      end
      -- Return first endpoint for backward compatibility
      return parsed_result[1]
    else
      -- Single endpoint
      parsed_result.framework = self.name
      self:_enhance_endpoint(parsed_result, file_path)
      return parsed_result
    end
  end

  return nil
end

---Hook for framework-specific endpoint enhancement
function Framework:_enhance_endpoint(parsed_endpoint, file_path)
  -- Default implementation - can be overridden by subclasses
  -- Add basic framework metadata
  parsed_endpoint.metadata = parsed_endpoint.metadata or {}
  parsed_endpoint.metadata.framework = self.name

  -- Extract controller name from file path if not already set
  if not parsed_endpoint.metadata.controller_name then
    local controller_name = self:getControllerName(file_path)
    if controller_name then
      parsed_endpoint.metadata.controller_name = controller_name
    end
  end
end

---Extract controller name from file path using configured extractors
function Framework:getControllerName(file_path)
  if not self.config.controller_extractors then
    return nil
  end

  for _, extractor in ipairs(self.config.controller_extractors) do
    local match = file_path:match(extractor.pattern)
    if match then
      if extractor.transform then
        return extractor.transform(match)
      else
        return match
      end
    end
  end

  return nil
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

  -- Perform search and parse all matching lines
  local discovered_endpoints = self:_search_and_parse(options)

  -- Post-process endpoints (remove duplicates, etc.)
  discovered_endpoints = self:_post_process_endpoints(discovered_endpoints)

  log.framework_debug(string.format("Found %d endpoints with %s", #discovered_endpoints, self.name))

  return discovered_endpoints
end

---Searches files and parses matching lines using framework parser
function Framework:_search_and_parse()
  local search_command = self:get_search_cmd()

  log.framework_debug("Executing search: " .. search_command)

  local search_result = vim.fn.system(search_command)
  if vim.v.shell_error ~= 0 then
    log.framework_debug("Search command failed: " .. search_result)
    return {}
  end

  local found_endpoints = {}
  local result_lines = vim.split(search_result, "\n", { trimempty = true })

  for _, result_line in ipairs(result_lines) do
    local endpoints = self:_parse_result_line(result_line)
    for _, endpoint in ipairs(endpoints) do
      table.insert(found_endpoints, endpoint)
    end
  end

  return found_endpoints
end

---Parses a ripgrep result line using framework parser
function Framework:_parse_result_line(result_line)
  if not result_line or result_line == "" then
    return {}
  end

  -- Parse ripgrep output format: file:line:col:content
  local source_file_path, source_line_number, source_column_position, line_content =
    result_line:match "([^:]+):(%d+):(%d+):(.*)"
  if not source_file_path or not source_line_number or not source_column_position or not line_content then
    return {}
  end

  local line_num = tonumber(source_line_number) or 1
  local col_pos = tonumber(source_column_position) or 1

  -- Use parser's parse method directly
  local endpoints = {}
  if self.parser then
    local parsed_result = self.parser:parse_content(line_content, source_file_path, line_num, col_pos)
    if parsed_result then
      if type(parsed_result) == "table" and #parsed_result > 0 then
        -- Array of endpoints
        for _, endpoint in ipairs(parsed_result) do
          endpoint.framework = self.name
          self:_enhance_endpoint(endpoint, source_file_path)
          table.insert(endpoints, endpoint)
        end
      else
        -- Single endpoint
        parsed_result.framework = self.name
        self:_enhance_endpoint(parsed_result, source_file_path)
        endpoints = { parsed_result }
      end
    end
  else
    -- Fallback to framework's parse method
    local single_endpoint = self:parse(line_content, source_file_path, line_num, col_pos)
    if single_endpoint then
      endpoints = { single_endpoint }
    end
  end

  -- Enhance each endpoint with framework metadata
  for _, endpoint in ipairs(endpoints) do
    endpoint.framework = self.name
    endpoint.file_path = endpoint.file_path or source_file_path
    endpoint.line_number = endpoint.line_number or line_num
    endpoint.column = endpoint.column or col_pos

    -- Generate display value if not provided
    if not endpoint.display_value and endpoint.method and endpoint.endpoint_path then
      endpoint.display_value = endpoint.method .. " " .. endpoint.endpoint_path
    end
  end

  return endpoints
end

---Post-processes endpoints to remove duplicates and clean up
function Framework:_post_process_endpoints(endpoints)
  -- Remove duplicates based on method + path only (ignore file/line differences)
  local seen = {}
  local unique_endpoints = {}

  for _, endpoint in ipairs(endpoints) do
    local key = string.format("%s:%s", endpoint.method or "", endpoint.endpoint_path or "")

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

---Sets framework metadata on parsed endpoint
function Framework:_set_framework_metadata(parsed_endpoint, fields)
  if not parsed_endpoint.metadata then
    parsed_endpoint.metadata = {}
  end
  parsed_endpoint.metadata.framework = self.name

  if fields then
    for key, value in pairs(fields) do
      parsed_endpoint.metadata[key] = value
    end
  end
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
