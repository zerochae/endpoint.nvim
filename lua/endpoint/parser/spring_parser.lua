local Parser = require "endpoint.core.Parser"

---@class endpoint.SpringParser
local SpringParser = setmetatable({}, { __index = Parser })
SpringParser.__index = SpringParser

---Creates a new SpringParser instance
function SpringParser:new()
  local spring_parser = Parser:new { parser_name = "spring_parser", framework_name = "spring", language = "java" }
  setmetatable(spring_parser, self)
  return spring_parser
end

---Extracts base path from Spring controller file
function SpringParser:extract_base_path(file_path, line_number)
  -- Read file content around the class definition
  local file = io.open(file_path, "r")
  if not file then
    return ""
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

  -- Look backwards for class-level @RequestMapping
  for i = math.min(line_number, #lines), 1, -1 do
    local line = lines[i]

    -- Check if this is a class declaration
    if line:match "class%s+%w+" then
      -- Look for @RequestMapping on this class or preceding lines
      for j = math.max(1, i - 5), i do
        local annotation_line = lines[j]
        local base_path = annotation_line:match "@RequestMapping%s*%(%s*[\"']([^\"']+)[\"']"
        if base_path then
          return base_path
        end
        base_path = annotation_line:match "@RequestMapping%s*%([^%)]*value%s*=%s*[\"']([^\"']+)[\"']"
        if base_path then
          return base_path
        end
        base_path = annotation_line:match "@RequestMapping%s*%([^%)]*path%s*=%s*[\"']([^\"']+)[\"']"
        if base_path then
          return base_path
        end
      end
      break
    end
  end

  return ""
end

---Extracts endpoint path from Spring annotation content
function SpringParser:extract_endpoint_path(content)
  -- Skip @RequestMapping unless it has method parameter
  if content:match "@RequestMapping" and not content:match "@RequestMapping.*method%s*=" then
    return nil
  end

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

  -- @RequestMapping with method parameter (only method-level endpoints)
  if content:match "@RequestMapping.*method%s*=" then
    -- @RequestMapping(value = "/path", method = ...)
    path = content:match "@RequestMapping%s*%([^%)]*value%s*=%s*[\"']([^\"']+)[\"']"
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
  end

  -- @GetMapping, @PostMapping, etc. without parentheses - root path
  if content:match "@%w+Mapping%s*$" and not content:match "@RequestMapping%s*$" then
    return "/"
  end

  return nil
end

---Extracts HTTP method from Spring annotation content
function SpringParser:extract_method(content)
  -- Extract from annotation type
  local annotation = content:match "@(%w+)Mapping"
  if annotation then
    if annotation == "Get" then
      return "GET"
    elseif annotation == "Post" then
      return "POST"
    elseif annotation == "Put" then
      return "PUT"
    elseif annotation == "Delete" then
      return "DELETE"
    elseif annotation == "Patch" then
      return "PATCH"
    end
  end

  -- Extract from @RequestMapping method parameter
  local method = content:match "@RequestMapping.-method%s*=%s*[^%.]*%.(%w+)"
  if method then
    return method:upper()
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

return SpringParser
