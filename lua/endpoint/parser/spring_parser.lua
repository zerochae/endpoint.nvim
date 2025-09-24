local Parser = require "endpoint.core.Parser"

---@class endpoint.SpringParser
local SpringParser = setmetatable({}, { __index = Parser })
SpringParser.__index = SpringParser

-- ========================================
-- PUBLIC METHODS
-- ========================================

---Creates a new SpringParser instance
function SpringParser:new()
  local spring_parser = Parser:new { parser_name = "spring_parser", framework_name = "spring", language = "java" }
  setmetatable(spring_parser, self)
  return spring_parser
end

---Extracts base path from Spring controller file
function SpringParser:extract_base_path(file_path, line_number)
  local lines = self:_read_file_lines(file_path, line_number)
  if not lines then
    return ""
  end

  return self:_find_class_level_request_mapping(lines, line_number)
end

---Extracts endpoint path from Spring annotation content
function SpringParser:extract_endpoint_path(content)
  -- Skip @RequestMapping unless it has method parameter
  if self:_is_class_level_request_mapping(content) then
    return nil
  end

  -- Try different path extraction patterns
  local path = self:_extract_path_from_specific_mapping(content)
  if path then
    return path
  end

  path = self:_extract_path_from_request_mapping_with_method(content)
  if path then
    return path
  end

  -- Handle mappings without parentheses
  if self:_is_root_path_mapping(content) then
    return "/"
  end

  return nil
end

---Extracts HTTP method from Spring annotation content
function SpringParser:extract_method(content)
  -- Try to extract from specific mapping annotation
  local method = self:_extract_method_from_specific_mapping(content)
  if method then
    return method
  end

  -- Try to extract from @RequestMapping method parameter
  method = self:_extract_method_from_request_mapping(content)
  if method then
    return method
  end

  -- Default for @RequestMapping without method
  return "GET"
end

---Validates if content contains Spring annotations
function SpringParser:is_content_valid_for_parsing(content)
  if not Parser.is_content_valid_for_parsing(self, content) then
    return false
  end

  -- Skip comments (lines starting with //)
  if content:match "^%s*//" then
    return false
  end

  -- Check if content contains Spring mapping annotations (including multiline)
  return content:match "@%w*Mapping" ~= nil or content:match "@%w*Mapping%s*%(" ~= nil
end

---Override parse_content to handle multiline Spring annotations and multiple HTTP methods
function SpringParser:parse_content(content, file_path, line_number, column)
  -- First try the standard parsing
  local result = Parser.parse_content(self, content, file_path, line_number, column)
  if result then
    -- Check if this is a @RequestMapping with multiple methods
    local extended_content = content
    local end_line = nil

    -- If this looks incomplete, get extended content
    if self:_looks_like_incomplete_spring_annotation(content) then
      local start_column
      extended_content, end_line, start_column = self:_get_extended_annotation_content(file_path, line_number)
      if not extended_content then
        return result
      end
      if start_column then
        column = start_column
      end
    end

    -- Check for multiple methods in @RequestMapping
    if extended_content:match "@RequestMapping" then
      local methods = self:_extract_methods_from_request_mapping(extended_content)
      if #methods > 1 then
        -- Create multiple endpoints for each method
        local endpoints = {}
        local base_path = self:extract_base_path(file_path, line_number)
        local endpoint_path = self:extract_endpoint_path(extended_content, file_path, line_number)
        local full_path = self:combine_paths(base_path, endpoint_path)

        for _, method in ipairs(methods) do
          local endpoint = {
            method = method:upper(),
            endpoint_path = full_path,
            file_path = file_path,
            line_number = line_number,
            column = column,
            display_value = method:upper() .. " " .. full_path,
            confidence = self:get_parsing_confidence(extended_content),
            tags = { "java", "spring", "request_mapping" },
            metadata = self:create_metadata("request_mapping", {
              methods_count = #methods,
              has_multiple_methods = true,
            }, extended_content),
          }
          if end_line then
            endpoint.end_line_number = end_line
          end
          table.insert(endpoints, endpoint)
        end
        return endpoints
      end
    end

    -- Single method case
    if end_line then
      result.end_line_number = end_line
    end
    return result
  end

  -- If standard parsing failed and this looks like an incomplete annotation,
  -- try to read extended context from the file
  if self:_looks_like_incomplete_spring_annotation(content) then
    local extended_content, end_line, start_column = self:_get_extended_annotation_content(file_path, line_number)
    if extended_content then
      if start_column then
        column = start_column
      end
      -- Check for multiple methods in extended content
      if extended_content:match "@RequestMapping" then
        local methods = self:_extract_methods_from_request_mapping(extended_content)
        if #methods > 1 then
          -- Create multiple endpoints for each method
          local endpoints = {}
          local base_path = self:extract_base_path(file_path, line_number)
          local endpoint_path = self:extract_endpoint_path(extended_content, file_path, line_number)
          local full_path = self:combine_paths(base_path, endpoint_path)

          for _, method in ipairs(methods) do
            local endpoint = {
              method = method:upper(),
              endpoint_path = full_path,
              file_path = file_path,
              line_number = line_number,
              column = column,
              display_value = method:upper() .. " " .. full_path,
              confidence = self:get_parsing_confidence(extended_content),
              tags = { "java", "spring", "request_mapping" },
              metadata = self:create_metadata("request_mapping", {
                methods_count = #methods,
                has_multiple_methods = true,
              }, extended_content),
            }
            if end_line then
              endpoint.end_line_number = end_line
            end
            table.insert(endpoints, endpoint)
          end
          return endpoints
        end
      end

      -- Single method case
      local extended_result = Parser.parse_content(self, extended_content, file_path, line_number, column)
      if extended_result and end_line then
        extended_result.end_line_number = end_line
      end
      return extended_result
    end
  end

  return nil
end

---Gets parsing confidence for Spring annotations
function SpringParser:get_parsing_confidence(content)
  if not self:is_content_valid_for_parsing(content) then
    return 0.0
  end

  local base_confidence = 0.8
  local confidence_boost = 0

  -- Boost for specific mapping annotations
  if
    content:match "@GetMapping"
    or content:match "@PostMapping"
    or content:match "@PutMapping"
    or content:match "@DeleteMapping"
    or content:match "@PatchMapping"
  then
    confidence_boost = confidence_boost + 0.15
  end

  -- Boost for well-formed paths
  local path = self:extract_endpoint_path(content)
  if path and path:match "^/" then
    confidence_boost = confidence_boost + 0.05
  end

  return math.min(base_confidence + confidence_boost, 1.0)
end

-- ========================================
-- PRIVATE METHODS
-- ========================================

---Reads file lines up to specified line number
function SpringParser:_read_file_lines(file_path, line_number)
  local file = io.open(file_path, "r")
  if not file then
    return nil
  end

  local lines = {}
  local current_line = 1
  for line in file:lines() do
    table.insert(lines, line)
    if current_line >= line_number then
      break
    end
    current_line = current_line + 1
  end
  file:close()

  return lines
end

---Finds class-level @RequestMapping annotation
function SpringParser:_find_class_level_request_mapping(lines, line_number)
  -- Look backwards for class-level @RequestMapping
  for i = math.min(line_number, #lines), 1, -1 do
    local line = lines[i]

    -- Check if this is a class declaration
    if line:match "class%s+%w+" then
      -- Look for @RequestMapping on this class or preceding lines
      for j = math.max(1, i - 5), i do
        local annotation_line = lines[j]
        local base_path = self:_extract_request_mapping_path(annotation_line)
        if base_path then
          return base_path
        end
      end
      break
    end
  end

  return ""
end

---Extracts path from @RequestMapping annotation
function SpringParser:_extract_request_mapping_path(annotation_line)
  -- @RequestMapping("/path")
  local base_path = annotation_line:match "@RequestMapping%s*%(%s*[\"']([^\"']+)[\"']"
  if base_path then
    return base_path
  end

  -- @RequestMapping(value = "/path")
  base_path = annotation_line:match "@RequestMapping%s*%([^%)]*value%s*=%s*[\"']([^\"']+)[\"']"
  if base_path then
    return base_path
  end

  -- @RequestMapping(path = "/path")
  base_path = annotation_line:match "@RequestMapping%s*%([^%)]*path%s*=%s*[\"']([^\"']+)[\"']"
  if base_path then
    return base_path
  end

  return nil
end

---Checks if this is a class-level @RequestMapping (should be skipped)
function SpringParser:_is_class_level_request_mapping(content)
  return content:match "@RequestMapping" and not content:match "@RequestMapping.*method%s*="
end

---Extracts path from specific mapping annotations (@GetMapping, @PostMapping, etc.)
function SpringParser:_extract_path_from_specific_mapping(content)
  -- Handle multiline patterns by removing line breaks and extra spaces
  local normalized_content = content:gsub("%s+", " "):gsub("[\r\n]+", " ")

  -- @GetMapping("/path"), @PostMapping(value = "/path"), etc.
  local path = normalized_content:match "@%w+Mapping%s*%(%s*[\"']([^\"']+)[\"']"
  if path and not normalized_content:match "@RequestMapping" then
    return path
  end

  -- @GetMapping(value = "/path") or @GetMapping( value = "/path" )
  path = normalized_content:match "@%w+Mapping%s*%(%s*value%s*=%s*[\"']([^\"']+)[\"']"
  if path and not normalized_content:match "@RequestMapping" then
    return path
  end

  -- @GetMapping(path = "/path") or @GetMapping( path = "/path" )
  path = normalized_content:match "@%w+Mapping%s*%(%s*path%s*=%s*[\"']([^\"']+)[\"']"
  if path and not normalized_content:match "@RequestMapping" then
    return path
  end

  return nil
end

---Extracts path from @RequestMapping with method parameter
function SpringParser:_extract_path_from_request_mapping_with_method(content)
  -- Handle multiline patterns by normalizing whitespace
  local normalized_content = content:gsub("%s+", " "):gsub("[\r\n]+", " ")

  if not normalized_content:match "@RequestMapping.*method%s*=" then
    return nil
  end

  -- @RequestMapping(value = "/path", method = ...) or multiline equivalent
  local path = normalized_content:match "@RequestMapping%s*%([^%)]*value%s*=%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  -- @RequestMapping(path = "/path", method = ...) or multiline equivalent
  path = normalized_content:match "@RequestMapping%s*%([^%)]*path%s*=%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  -- @RequestMapping("/path", method = ...) or multiline equivalent
  path = normalized_content:match "@RequestMapping%s*%(%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  return nil
end

---Checks if this is a root path mapping without parentheses
function SpringParser:_is_root_path_mapping(content)
  return content:match "@%w+Mapping%s*$" and not content:match "@RequestMapping%s*$"
end

---Extracts HTTP method from specific mapping annotations
function SpringParser:_extract_method_from_specific_mapping(content)
  local annotation = content:match "@(%w+)Mapping"
  if annotation then
    local method_mapping = {
      Get = "GET",
      Post = "POST",
      Put = "PUT",
      Delete = "DELETE",
      Patch = "PATCH",
    }
    return method_mapping[annotation]
  end
  return nil
end

---Extracts HTTP method from @RequestMapping method parameter
function SpringParser:_extract_method_from_request_mapping(content)
  -- Handle multiline patterns by normalizing whitespace
  local normalized_content = content:gsub("%s+", " "):gsub("[\r\n]+", " ")

  local method = normalized_content:match "@RequestMapping.-method%s*=%s*[^%.]*%.(%w+)"
  if method then
    return method:upper()
  end
  return nil
end

---Extracts all HTTP methods from @RequestMapping method parameter (supports arrays)
function SpringParser:_extract_methods_from_request_mapping(content)
  local methods = {}
  -- Handle multiline patterns by normalizing whitespace
  local normalized_content = content:gsub("%s+", " "):gsub("[\r\n]+", " ")

  -- Pattern for array: method = {RequestMethod.GET, RequestMethod.POST}
  local method_section = normalized_content:match "@RequestMapping.-method%s*=%s*{([^}]+)}"
  if method_section then
    -- Extract all RequestMethod.XXX patterns
    for method in method_section:gmatch "RequestMethod%.(%w+)" do
      table.insert(methods, method:upper())
    end
    return methods
  end

  -- Pattern for single method: method = RequestMethod.GET
  local single_method = normalized_content:match "@RequestMapping.-method%s*=%s*[^%.]*%.(%w+)"
  if single_method then
    table.insert(methods, single_method:upper())
    return methods
  end

  return methods
end

---Checks if content looks like an incomplete Spring annotation
function SpringParser:_looks_like_incomplete_spring_annotation(content)
  -- Check for annotation that starts but doesn't complete on the same line
  if content:match "@%w*Mapping%s*%(" and not content:match "@%w*Mapping%s*%(.*%)" then
    return true
  end
  return false
end

---Gets extended annotation content by reading multiple lines from file
function SpringParser:_get_extended_annotation_content(file_path, start_line)
  if not file_path then
    return nil, nil, nil
  end

  local file = io.open(file_path, "r")
  if not file then
    return nil, nil, nil
  end

  local lines = {}
  local current_line = 1
  for line in file:lines() do
    table.insert(lines, line)
    current_line = current_line + 1
  end
  file:close()

  if start_line > #lines then
    return nil, nil, nil
  end

  -- Find the exact column where annotation starts
  local start_column = nil
  local start_line_content = lines[start_line]
  if start_line_content then
    local annotation_start = start_line_content:find("@%w*Mapping")
    if annotation_start then
      start_column = annotation_start
    end
  end

  -- Start from the current line and read until we find a complete annotation
  local extended_content = ""
  local paren_count = 0
  local found_opening = false
  local end_line = start_line

  for i = start_line, math.min(start_line + 10, #lines) do -- Limit to 10 lines
    local line = lines[i]
    extended_content = extended_content .. " " .. line:gsub("^%s+", "")
    end_line = i

    -- Count parentheses to find complete annotation
    for char in line:gmatch "." do
      if char == "(" then
        paren_count = paren_count + 1
        found_opening = true
      elseif char == ")" then
        paren_count = paren_count - 1
      end
    end

    -- If we've found opening parenthesis and closed all of them, we have complete annotation
    if found_opening and paren_count == 0 then
      break
    end
  end

  -- Clean up the extended content
  extended_content = extended_content:gsub("^%s+", ""):gsub("%s+", " ")

  return extended_content, end_line, start_column
end

return SpringParser
