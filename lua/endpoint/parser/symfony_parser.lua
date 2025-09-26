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
function SymfonyParser:extract_endpoint_path(content, file_path, line_number)
  -- Use multiline extraction for better accuracy
  if file_path and line_number then
    local path, end_line = self:_extract_path_multiline(file_path, line_number, content)
    if path then
      -- Store end_line_number for highlighting
      self._last_end_line_number = end_line
      return path
    end
  end

  -- Fallback to single line extraction
  self._last_end_line_number = nil
  return self:_extract_path_single_line(content)
end

---Extracts path from single line content
function SymfonyParser:_extract_path_single_line(content)
  -- Handle multiline patterns by normalizing whitespace
  local normalized_content = content:gsub("%s+", " "):gsub("[\r\n]+", " ")

  -- Skip controller-level @Route (without methods parameter)
  if self:_is_controller_level_route(normalized_content) then
    return nil
  end

  -- Try different path extraction patterns with normalized content
  local path = self:_extract_path_from_php8_attributes(normalized_content)
  if path then
    return path
  end

  path = self:_extract_path_from_annotations(normalized_content)
  if path then
    return path
  end

  path = self:_extract_path_from_docblock(normalized_content)
  if path then
    return path
  end

  return nil
end

---Extracts path handling multiline annotations
function SymfonyParser:_extract_path_multiline(file_path, start_line, content)
  -- First try single line extraction
  local path = self:_extract_path_single_line(content)
  if path then
    return path, nil  -- Single line, no end_line
  end

  -- If it's a multiline annotation, read the file to find the complete annotation
  if self:_is_multiline_annotation(content) then
    local file = io.open(file_path, "r")
    if not file then
      return nil, nil
    end

    local lines = {}
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()

    -- Read the next few lines to find the complete annotation
    local multiline_content = content
    local extracted_path = nil
    local annotation_end_line = nil

    for i = start_line + 1, math.min(start_line + 15, #lines) do
      local next_line = lines[i]
      if next_line then
        multiline_content = multiline_content .. " " .. next_line:gsub("^%s+", ""):gsub("%s+$", "")

        -- Try to extract path from accumulated content (but don't return yet)
        if not extracted_path then
          extracted_path = self:_extract_path_single_line(multiline_content)
        end

        -- If we hit closing bracket followed by closing parenthesis, this is the end
        if next_line:match "%s*%]%s*$" then
          annotation_end_line = i
          break
        end
      end
    end

    -- Return the path and the actual end line of the annotation
    if extracted_path and annotation_end_line then
      return extracted_path, annotation_end_line
    elseif extracted_path then
      -- Fallback: use last processed line if no closing bracket found
      return extracted_path, math.min(start_line + 10, #lines)
    end
  end

  return nil, nil
end

---Checks if annotation definition spans multiple lines
function SymfonyParser:_is_multiline_annotation(content)
  -- Check if content has annotation start but no closing bracket
  return (content:match "#%[Route%(%s*$" or content:match "@Route%(%s*$" or content:match "\\* @Route%(%s*$")
end

---Extracts HTTP method from Symfony annotation content
function SymfonyParser:extract_method(content)
  -- Handle multiline patterns by normalizing whitespace
  local normalized_content = content:gsub("%s+", " "):gsub("[\r\n]+", " ")

  -- Try to extract from methods parameter
  local methods = self:_extract_methods_from_annotation(normalized_content)
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

  -- Extract path (this will handle multiline extraction and set end_line_number)
  local endpoint_path = self:extract_endpoint_path(content, file_path, line_number)
  if not endpoint_path then
    return nil
  end

  -- Get base path and combine
  local base_path = self:extract_base_path(file_path, line_number)
  local full_path = self:_combine_paths(base_path, endpoint_path)

  -- Extract all methods using multiline-aware extraction
  local methods = self:_extract_methods_multiline(content, file_path, line_number)
  if #methods == 0 then
    methods = { "GET" }
  end

  -- Store end_line_number before creating endpoints
  local end_line_number = self._last_end_line_number

  -- Calculate correct column position for annotation start
  local correct_column = self:_calculate_annotation_column(content, file_path, line_number, column)

  -- Create endpoint for each method
  local endpoints = {}
  for _, method in ipairs(methods) do
    local endpoint = {
      method = method:upper(),
      endpoint_path = full_path,
      file_path = file_path,
      line_number = line_number,
      column = correct_column,
      display_value = method:upper() .. " " .. full_path,
      confidence = self:get_parsing_confidence(content),
      tags = { "php", "symfony", "route" },
      metadata = self:create_metadata("route", {
        annotation_type = self:_detect_annotation_type(content),
        methods_count = #methods,
      }, content),
    }

    -- Add end_line_number if multiline
    if end_line_number then
      endpoint.end_line_number = end_line_number
    end

    table.insert(endpoints, endpoint)
  end

  -- Clean up stored end_line_number
  self._last_end_line_number = nil

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
      local multiline_content = ""
      local in_multiline_route = false

      for j = math.max(1, i - 15), i do
        local annotation_line = lines[j]

        -- Check if we're starting a multiline Route attribute
        if annotation_line:match "#%[Route%(%s*$" or annotation_line:match "#%[Route%(%s*[^%]]*$" then
          in_multiline_route = true
          multiline_content = annotation_line
        elseif in_multiline_route then
          multiline_content = multiline_content .. " " .. annotation_line:gsub("^%s+", ""):gsub("%s+$", "")
          -- Check if we've reached the end of the attribute
          if annotation_line:match "%s*%]%s*$" then
            in_multiline_route = false
            local base_path = self:_extract_controller_route_path(multiline_content)
            if base_path then
              return base_path
            end
            multiline_content = ""
          end
        else
          -- Try single line extraction
          local base_path = self:_extract_controller_route_path(annotation_line)
          if base_path then
            return base_path
          end
        end
      end
      break
    end
  end

  return ""
end

---Extracts path from controller-level @Route annotation
function SymfonyParser:_extract_controller_route_path(annotation_line)
  -- PHP 8+ attributes: #[Route('/api')] (positional)
  local path = annotation_line:match "#%[Route%(%s*[\"']([^\"']+)[\"']"
  if path and not annotation_line:match "methods" then
    return path
  end

  -- PHP 8+ attributes: #[Route(path: '/api')] (named parameter)
  path = annotation_line:match "path%s*:%s*[\"']([^\"']+)[\"']"
  if path and annotation_line:match "#%[Route%(" and not annotation_line:match "methods" then
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

---Extracts path from PHP 8+ attributes: #[Route('/path')] or #[Route(path: '/path')]
function SymfonyParser:_extract_path_from_php8_attributes(content)
  -- First try positional parameter: #[Route('/path')]
  local path = content:match "#%[Route%(%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  -- Then try named parameter: #[Route(...path: '/path'...)] - anywhere in the attributes
  path = content:match "path%s*:%s*[\"']([^\"']+)[\"']"
  if path and content:match "#%[Route%(" then
    return path
  end

  return nil
end

---Extracts path from direct annotations: @Route("/path")
function SymfonyParser:_extract_path_from_annotations(content)
  return content:match "@Route%(%s*[\"']([^\"']+)[\"']"
end

---Extracts path from docblock annotations: * @Route("/path")
function SymfonyParser:_extract_path_from_docblock(content)
  -- Try single line: * @Route("/path")
  local path = content:match "\\* @Route%(%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  -- Try multiline DocBlock: extract path from anywhere in the comment
  if content:match "\\* @Route%(" then
    -- Look for path anywhere in the normalized content
    path = content:match "[\"']([^\"']*%/[^\"']*)[\"']"
    if path then
      return path
    end
  end

  return nil
end

---Extracts HTTP methods using multiline-aware extraction
function SymfonyParser:_extract_methods_multiline(content, file_path, line_number)
  -- First try single line extraction
  local methods = self:_extract_methods_from_annotation(content)
  if #methods > 0 then
    return methods
  end

  -- If it's a multiline annotation, use the complete annotation content
  if self:_is_multiline_annotation(content) and file_path and line_number then
    local file = io.open(file_path, "r")
    if not file then
      return {}
    end

    local lines = {}
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()

    -- Read the annotation content across multiple lines
    local multiline_content = content
    for i = line_number + 1, math.min(line_number + 10, #lines) do
      local next_line = lines[i]
      if next_line then
        multiline_content = multiline_content .. " " .. next_line:gsub("^%s+", ""):gsub("%s+$", "")

        -- Try to extract methods from accumulated content
        local extracted_methods = self:_extract_methods_from_annotation(multiline_content)
        if #extracted_methods > 0 then
          return extracted_methods
        end

        -- If we hit closing bracket, stop
        if next_line:match "%s*%]%s*$" then
          break
        end
      end
    end
  end

  return {}
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
  -- Handle multiline patterns by normalizing whitespace
  local normalized_content = content:gsub("%s+", " "):gsub("[\r\n]+", " ")

  return normalized_content:match "#%[Route%(" or normalized_content:match "@Route%(" or normalized_content:match "\\* @Route%("
end

---Calculates correct column position for annotation start
function SymfonyParser:_calculate_annotation_column(content, file_path, line_number, ripgrep_column)
  -- ripgrep in multiline mode often returns column 1, so we need to calculate the actual position
  if ripgrep_column and ripgrep_column > 1 then
    return ripgrep_column -- Trust ripgrep if it gives a meaningful column
  end

  -- Read the actual line to find the annotation start position
  local file = io.open(file_path, "r")
  if not file then
    return 1
  end

  local current_line = 1
  for line in file:lines() do
    if current_line == line_number then
      file:close()
      -- Find the position of # or @ character (1-based)
      local hash_pos = line:find("#%[Route%(")
      local at_pos = line:find("@Route%(")
      local docblock_pos = line:find("\\* @Route%(")

      local annotation_pos = hash_pos or at_pos or docblock_pos
      if annotation_pos then
        return annotation_pos
      end
      break
    end
    current_line = current_line + 1
  end
  file:close()

  return 1 -- Fallback
end

return SymfonyParser

