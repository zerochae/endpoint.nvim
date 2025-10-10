local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"

---@class endpoint.Framework
local Framework = class "Framework"

---Creates a new Framework instance
function Framework:initialize(fields)
  if fields then
    for key, value in pairs(fields) do
      self[key] = value
    end
  end

  self:_validate_config()
  self:_setup_detector_and_parser()
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
    self.detector = Detector:new(
      self.config.detector.dependencies or {},
      self.config.detector.manifest_files or {},
      self.config.detector.name or (self.name .. "_detection")
    )
  end

  if self.config.parser then
    self.parser = self.config.parser:new()
  end
end

---Initialize framework components (called lazily)
function Framework:_initialize()
  self:_setup_detector_and_parser()
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

  local parsed_endpoint = self.parser:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- Set framework name
    parsed_endpoint.framework = self.name

    -- Call framework-specific enhancement hook
    self:_enhance_endpoint(parsed_endpoint, file_path)
  end

  return parsed_endpoint
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
function Framework:get_search_cmd(method)
  if not self.config.patterns then
    error("Patterns not configured for framework: " .. self.name)
  end

  local rg = require "endpoint.utils.rg"

  -- Filter patterns by method if specified
  local patterns_to_search = self.config.patterns
  if method and method ~= "" then
    patterns_to_search = {}
    if self.config.patterns[method:upper()] then
      patterns_to_search[method:upper()] = self.config.patterns[method:upper()]
    end
  end

  -- Create search options
  local search_options = {
    method_patterns = patterns_to_search,
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
function Framework:_search_and_parse(options)
  options = options or {}
  local search_command = self:get_search_cmd(options.method)

  log.framework_debug("Executing search: " .. search_command)

  local search_result = vim.fn.system(search_command)
  if vim.v.shell_error ~= 0 then
    log.framework_debug("Search command failed: " .. search_result)
    return {}
  end

  local result_lines = vim.split(search_result, "\n", { trimempty = true })
  local found_endpoints = {}

  for _, result_line in ipairs(result_lines) do
    vim.list_extend(found_endpoints, self:_parse_result_line(result_line))
  end

  return found_endpoints
end

---Parses a ripgrep result line using framework parser
function Framework:_parse_result_line(result_line)
  if not result_line or result_line == "" then
    return {}
  end

  -- Use rg util to parse result line (handles Windows and Unix paths)
  local rg_util = require "endpoint.utils.rg"
  local parsed = rg_util.parse_result_line(result_line)

  if not parsed then
    return {}
  end

  local source_file_path = parsed.file_path
  local line_num = parsed.line_number
  local col_pos = parsed.column
  local line_content = parsed.content

  local endpoints = {}
  if self.parser then
    local endpoint_entry = self.parser:parse_content(line_content, source_file_path, line_num, col_pos)
    if endpoint_entry then
      -- Normalize to array for consistent handling
      local endpoint_list = {}
      if endpoint_entry.method then
        -- Single endpoint object
        table.insert(endpoint_list, endpoint_entry)
      else
        -- Array of endpoints
        endpoint_list = endpoint_entry
      end

      -- Process each endpoint
      for _, single_endpoint in ipairs(endpoint_list) do
        single_endpoint.framework = self.name
        self:_enhance_endpoint(single_endpoint, source_file_path)
        table.insert(endpoints, single_endpoint)
      end
    end
  else
    -- Fallback to framework's parse method
    local endpoint_entry = self:parse(line_content, source_file_path, line_num, col_pos)
    if endpoint_entry then
      endpoints = { endpoint_entry }
    end
  end

  -- Enhance each endpoint with ripgrep result metadata
  for _, endpoint in ipairs(endpoints) do
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
  -- Remove duplicates based on method + path + file (preserve endpoints from different files)
  local seen = {}
  local unique_endpoints = {}

  for _, endpoint in ipairs(endpoints) do
    local key = string.format("%s:%s:%s", endpoint.method or "", endpoint.endpoint_path or "", endpoint.file_path or "")

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
