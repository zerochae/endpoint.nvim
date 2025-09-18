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

  -- Check if content contains Spring mapping annotations
  return content:match "@%w*Mapping" ~= nil
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
  -- @GetMapping("/path"), @PostMapping(value = "/path"), etc.
  local path = content:match "@%w+Mapping%s*%(%s*[\"']([^\"']+)[\"']"
  if path and not content:match "@RequestMapping" then
    return path
  end

  -- @GetMapping(value = "/path")
  path = content:match "@%w+Mapping%s*%(%s*value%s*=%s*[\"']([^\"']+)[\"']"
  if path and not content:match "@RequestMapping" then
    return path
  end

  -- @GetMapping(path = "/path")
  path = content:match "@%w+Mapping%s*%(%s*path%s*=%s*[\"']([^\"']+)[\"']"
  if path and not content:match "@RequestMapping" then
    return path
  end

  return nil
end

---Extracts path from @RequestMapping with method parameter
function SpringParser:_extract_path_from_request_mapping_with_method(content)
  if not content:match "@RequestMapping.*method%s*=" then
    return nil
  end

  -- @RequestMapping(value = "/path", method = ...)
  local path = content:match "@RequestMapping%s*%([^%)]*value%s*=%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  -- @RequestMapping(path = "/path", method = ...)
  path = content:match "@RequestMapping%s*%([^%)]*path%s*=%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  -- @RequestMapping("/path", method = ...)
  path = content:match "@RequestMapping%s*%(%s*[\"']([^\"']+)[\"']"
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
      Patch = "PATCH"
    }
    return method_mapping[annotation]
  end
  return nil
end

---Extracts HTTP method from @RequestMapping method parameter
function SpringParser:_extract_method_from_request_mapping(content)
  local method = content:match "@RequestMapping.-method%s*=%s*[^%.]*%.(%w+)"
  if method then
    return method:upper()
  end
  return nil
end

return SpringParser
