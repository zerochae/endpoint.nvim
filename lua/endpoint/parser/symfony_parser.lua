local Parser = require "endpoint.core.Parser"

---@class endpoint.SymfonyParser
local SymfonyParser = setmetatable({}, { __index = Parser })
SymfonyParser.__index = SymfonyParser

-- ========================================
-- PUBLIC METHODS
-- ========================================

---Creates a new SymfonyParser instance
function SymfonyParser:new()
  local symfony_parser = Parser:new {
    parser_name = "symfony_parser",
    framework_name = "symfony",
    language = "php",
  }
  setmetatable(symfony_parser, self)
  return symfony_parser
end

---Extracts base path from Symfony controller file
function SymfonyParser:extract_base_path(file_path, line_number)
  local lines = self:_read_file_lines(file_path, line_number)
  if not lines then
    return ""
  end

  return self:_find_controller_level_route(lines, line_number)
end

---Extracts endpoint path from Symfony annotation content
function SymfonyParser:extract_endpoint_path(content, _, _)
  -- Skip controller-level @Route (without methods parameter)
  if self:_is_controller_level_route(content) then
    return nil
  end

  -- Try different path extraction patterns
  local path = self:_extract_path_from_php8_attributes(content)
  if path then
    return path
  end

  path = self:_extract_path_from_annotations(content)
  if path then
    return path
  end

  path = self:_extract_path_from_docblock(content)
  if path then
    return path
  end

  return nil
end

---Extracts HTTP method from Symfony annotation content
function SymfonyParser:extract_method(content)
  -- Try to extract from methods parameter
  local methods = self:_extract_methods_from_annotation(content)
  if #methods > 0 then
    return methods[1] -- Return first method
  end

  -- Default to GET if no methods specified
  return "GET"
end

---Override parse_content to handle multiple HTTP methods in Symfony
function SymfonyParser:parse_content(content, file_path, line_number, column)
  -- Only process if this looks like Symfony annotation
  if not self:is_content_valid_for_parsing(content) then
    return nil
  end

  -- Skip controller-level routes
  if self:_is_controller_level_route(content) then
    return nil
  end

  -- Extract path
  local endpoint_path = self:extract_endpoint_path(content, file_path, line_number)
  if not endpoint_path then
    return nil
  end

  -- Get base path and combine
  local base_path = self:extract_base_path(file_path, line_number)
  local full_path = self:_combine_paths(base_path, endpoint_path)

  -- Extract all methods (can be multiple)
  local methods = self:_extract_methods_from_annotation(content)
  if #methods == 0 then
    methods = { "GET" }
  end

  -- Create endpoint for each method
  local endpoints = {}
  for _, method in ipairs(methods) do
    table.insert(endpoints, {
      method = method:upper(),
      endpoint_path = full_path,
      file_path = file_path,
      line_number = line_number,
      column = column,
      display_value = method:upper() .. " " .. full_path,
      confidence = self:get_parsing_confidence(content),
      tags = { "php", "symfony", "route" },
      metadata = self:create_metadata("route", {
        annotation_type = self:_detect_annotation_type(content),
        methods_count = #methods,
      }, content),
    })
  end

  -- Return single endpoint if only one method, multiple if more
  if #endpoints == 1 then
    return endpoints[1]
  end

  return endpoints
end

---Validates if content contains Symfony annotations
function SymfonyParser:is_content_valid_for_parsing(content)
  if not Parser.is_content_valid_for_parsing(self, content) then
    return false
  end

  -- Check if content contains Symfony Route annotations
  return self:_is_symfony_route_content(content)
end

---Gets parsing confidence for Symfony annotations
function SymfonyParser:get_parsing_confidence(content)
  if not self:is_content_valid_for_parsing(content) then
    return 0.0
  end

  local base_confidence = 0.8
  local confidence_boost = 0

  -- Boost for PHP 8+ attributes
  if content:match "#%[Route%(" then
    confidence_boost = confidence_boost + 0.15
  end

  -- Boost for methods parameter
  if content:match "methods" then
    confidence_boost = confidence_boost + 0.1
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
function SymfonyParser:_read_file_lines(file_path, line_number)
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

---Finds controller-level @Route annotation
function SymfonyParser:_find_controller_level_route(lines, line_number)
  -- Look backwards for controller-level @Route
  for i = math.min(line_number, #lines), 1, -1 do
    local line = lines[i]

    -- Check if this is a class declaration
    if line:match "class%s+%w+" then
      -- Look for @Route on this class or preceding lines (including docblocks)
      for j = math.max(1, i - 10), i do
        local annotation_line = lines[j]
        local base_path = self:_extract_controller_route_path(annotation_line)
        if base_path then
          return base_path
        end
      end
      break
    end
  end

  return ""
end

---Extracts path from controller-level @Route annotation
function SymfonyParser:_extract_controller_route_path(annotation_line)
  -- PHP 8+ attributes: #[Route('/api')]
  local path = annotation_line:match "#%[Route%(%s*[\"']([^\"']+)[\"']"
  if path and not annotation_line:match "methods" then
    return path
  end

  -- Direct annotations: @Route("/api")
  path = annotation_line:match "@Route%(%s*[\"']([^\"']+)[\"']"
  if path and not annotation_line:match "methods" then
    return path
  end

  -- Docblock annotations: * @Route("/api")
  path = annotation_line:match "\\* @Route%(%s*[\"']([^\"']+)[\"']"
  if path and not annotation_line:match "methods" then
    return path
  end

  return nil
end

---Checks if this is a controller-level @Route (no methods parameter)
function SymfonyParser:_is_controller_level_route(content)
  -- If it contains methods parameter, it's a method-level route
  if content:match "methods" then
    return false
  end

  -- Check for @Route without methods parameter
  return content:match "@Route%s*%(" or content:match "#%[Route%(" or content:match "\\* @Route%s*%("
end

---Extracts path from PHP 8+ attributes: #[Route('/path')]
function SymfonyParser:_extract_path_from_php8_attributes(content)
  return content:match "#%[Route%(%s*[\"']([^\"']+)[\"']"
end

---Extracts path from direct annotations: @Route("/path")
function SymfonyParser:_extract_path_from_annotations(content)
  return content:match "@Route%(%s*[\"']([^\"']+)[\"']"
end

---Extracts path from docblock annotations: * @Route("/path")
function SymfonyParser:_extract_path_from_docblock(content)
  return content:match "\\* @Route%(%s*[\"']([^\"']+)[\"']"
end

---Extracts HTTP methods from methods parameter
function SymfonyParser:_extract_methods_from_annotation(content)
  local methods = {}

  -- Extract methods from various formats
  -- methods: ['GET', 'POST'] or methods={"GET", "POST"} or methods={GET, POST}
  local methods_section = content:match "methods[^%[%{]*([%[%{][^%]%}]*[%]%}])"
  if methods_section then
    -- Extract all method names within brackets
    for method in methods_section:gmatch "[\"']?([A-Z]+)[\"']?" do
      if method:match "^[A-Z]+$" then -- Only HTTP methods (all caps)
        table.insert(methods, method:upper())
      end
    end
  end

  return methods
end

---Combines base path with endpoint path
function SymfonyParser:_combine_paths(base, endpoint)
  if (not base or base == "") and endpoint then
    return endpoint
  end
  if (not endpoint or endpoint == "") and base then
    return base
  end

  -- Remove trailing slash from base and leading slash from endpoint
  base = base and base:gsub("/$", "")
  endpoint = endpoint and endpoint:gsub("^/", "")

  return base .. "/" .. endpoint
end

---Detects the type of annotation used
function SymfonyParser:_detect_annotation_type(content)
  if content:match "#%[Route%(" then
    return "php8_attribute"
  elseif content:match "\\* @Route%(" then
    return "docblock_annotation"
  elseif content:match "@Route%(" then
    return "direct_annotation"
  else
    return "unknown"
  end
end

---Checks if content looks like Symfony Route annotation
function SymfonyParser:_is_symfony_route_content(content)
  return content:match "#%[Route%(" or content:match "@Route%(" or content:match "\\* @Route%("
end

return SymfonyParser

