local Parser = require "endpoint.core.Parser"

---@class endpoint.DotNetParser
local DotNetParser = setmetatable({}, { __index = Parser })
DotNetParser.__index = DotNetParser

-- ========================================
-- PUBLIC METHODS
-- ========================================

---Creates a new DotNetParser instance
function DotNetParser:new()
  local dotnet_parser = Parser:new {
    parser_name = "dotnet_parser",
    framework_name = "dotnet",
    language = "csharp",
  }
  setmetatable(dotnet_parser, self)
  return dotnet_parser
end

---Extracts base path from .NET controller file
function DotNetParser:extract_base_path(file_path, line_number)
  return self:_get_controller_base_path(file_path, line_number)
end

---Extracts endpoint path from .NET attribute content
function DotNetParser:extract_endpoint_path(content, file_path, line_number)
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
  return self:_extract_path_single_line(content, file_path, line_number)
end

---Extracts path from single line content
function DotNetParser:_extract_path_single_line(content, file_path, line_number)
  -- Use _extract_route_info for better accuracy
  local _, endpoint_path = self:_extract_route_info(content, file_path, line_number)
  if endpoint_path then
    return endpoint_path
  end

  -- Fallback to attribute extraction
  local path = self:_extract_path_from_attributes(content)
  if path then
    return path
  end

  return nil
end

---Extracts path handling multiline attributes
function DotNetParser:_extract_path_multiline(file_path, start_line, content)
  -- First try single line extraction
  local path = self:_extract_path_single_line(content, file_path, start_line)
  if path then
    return path, nil  -- Single line, no end_line
  end

  -- If it's a multiline attribute, read the file to find the complete attribute
  if self:_is_multiline_attribute(content) then
    local file = io.open(file_path, "r")
    if not file then
      return nil, nil
    end

    local lines = {}
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()

    -- Read the next few lines to find the complete attribute
    local multiline_content = content
    local extracted_path = nil
    local attribute_end_line = nil

    for i = start_line + 1, math.min(start_line + 15, #lines) do
      local next_line = lines[i]
      if next_line then
        multiline_content = multiline_content .. " " .. next_line:gsub("^%s+", ""):gsub("%s+$", "")

        -- Try to extract path from accumulated content (but don't return yet)
        if not extracted_path then
          extracted_path = self:_extract_path_single_line(multiline_content, file_path, start_line)
        end

        -- If we hit closing parenthesis followed by closing bracket, this is the end
        if next_line:match "%s*%)%s*$" then
          attribute_end_line = i
          break
        end
      end
    end

    -- Return the path and the actual end line of the attribute
    if extracted_path and attribute_end_line then
      return extracted_path, attribute_end_line
    elseif extracted_path then
      -- Fallback: use last processed line if no closing parenthesis found
      return extracted_path, math.min(start_line + 10, #lines)
    end
  end

  return nil, nil
end

---Checks if attribute definition spans multiple lines
function DotNetParser:_is_multiline_attribute(content)
  -- Check if content has attribute start but no closing parenthesis
  -- Also check if content contains attribute but doesn't have a complete path on the same line
  local has_attribute_start = content:match "%[Http%w+%(" or content:match "%[Route%(" or content:match "app%.Map%w+%(" or content:match "endpoints%.Map%w+%("
  if not has_attribute_start then
    return false
  end

  -- If it has the attribute but doesn't have both opening and closing quotes with content, it's likely multiline
  local has_complete_path = content:match "%[Http%w+%([\"']([^\"']+)[\"']%)" or content:match "%[Route%([\"']([^\"']+)[\"']%)"
  return not has_complete_path
end

---Extracts HTTP method from .NET attribute content
function DotNetParser:extract_method(content, file_path, line_number)
  -- Use multiline-aware extraction
  local methods = self:_extract_methods_multiline(content, file_path, line_number)
  if #methods > 0 then
    return methods[1]:upper() -- Return first method
  end

  return "GET" -- Default fallback
end

---Override parse_content to add .NET-specific metadata and handle absolute paths
function DotNetParser:parse_content(content, file_path, line_number, column)
  -- Only process if this looks like .NET attribute content
  if not self:is_content_valid_for_parsing(content) then
    return nil
  end

  -- Additional check for commented code with file context
  if self:_is_commented_code(content, file_path, line_number) then
    return nil
  end

  -- Extract path (this will handle multiline extraction and set end_line_number)
  local endpoint_path = self:extract_endpoint_path(content, file_path, line_number)

  -- Get base path for combination
  local base_path = self:extract_base_path(file_path, line_number)

  -- DEBUG: Only use base path for truly empty HTTP method attributes (like [HttpGet] without any path)
  if not endpoint_path or endpoint_path == "" then
    -- Check if this is truly a standalone attribute without path (like [HttpGet] vs [HttpGet("path")])
    local is_standalone_attribute = content:match "%[Http%w+%]" and not content:match "%[Http%w+%("
    if is_standalone_attribute and base_path and base_path ~= "" then
      -- Use base path for standalone HTTP method attributes like [HttpGet] without path
      endpoint_path = base_path
    else
      return nil -- No route information available - this shouldn't happen for [HttpGet("path")] patterns
    end
  end

  -- Extract all methods using multiline-aware extraction
  local methods = self:_extract_methods_multiline(content, file_path, line_number)
  if #methods == 0 then
    methods = { "GET" }
  end

  -- Store end_line_number before creating endpoints
  local end_line_number = self._last_end_line_number

  -- Calculate correct column position for attribute start
  local correct_column = self:_calculate_attribute_column(content, file_path, line_number, column)

  -- Handle path combination logic
  local final_path
  if endpoint_path:match "^/" then
    -- Absolute path - use as is
    final_path = endpoint_path
  elseif endpoint_path:match "^api/" then
    -- Path starting with api/ - treat as absolute
    final_path = "/" .. endpoint_path
  else
    -- Always combine relative paths with base path
    final_path = self:_combine_paths(base_path, endpoint_path)
  end

  -- Create endpoint for each method
  local endpoints = {}
  for _, method in ipairs(methods) do
    local endpoint = {
      method = method:upper(),
      endpoint_path = final_path,
      file_path = file_path,
      line_number = line_number,
      column = correct_column,
      display_value = method:upper() .. " " .. final_path,
      confidence = self:get_parsing_confidence(content),
      tags = { "csharp", "dotnet", "attribute" },
      metadata = self:create_metadata("attribute", {
        attribute_type = self:_detect_attribute_type(content),
        has_route_template = self:_has_route_template(content),
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

---Validates if content contains .NET attributes
function DotNetParser:is_content_valid_for_parsing(content)
  if not Parser.is_content_valid_for_parsing(self, content) then
    return false
  end

  -- Skip commented code (/* */ style comments)
  if self:_is_commented_code(content) then
    return false
  end

  -- Check if content contains .NET attribute patterns
  return self:_is_dotnet_attribute_content(content)
end

---Gets parsing confidence for .NET attributes
function DotNetParser:get_parsing_confidence(content)
  if not self:is_content_valid_for_parsing(content) then
    return 0.0
  end

  local base_confidence = 0.9
  local confidence_boost = 0

  -- Boost for HTTP method attributes
  if content:match "%[Http%w+%]" or content:match "%[Http%w+%(" then
    confidence_boost = confidence_boost + 0.05
  end

  -- Boost for minimal API patterns
  if content:match "app%.Map%w+%(" or content:match "endpoints%.Map%w+%(" then
    confidence_boost = confidence_boost + 0.03
  end

  -- Boost for well-formed paths
  local path = self:extract_endpoint_path(content)
  if path and path:match "^/" then
    confidence_boost = confidence_boost + 0.02
  end

  return math.min(base_confidence + confidence_boost, 1.0)
end

-- ========================================
-- PRIVATE METHODS
-- ========================================

---Checks if content looks like .NET attribute content
function DotNetParser:_is_dotnet_attribute_content(content)
  -- Check for .NET attribute patterns
  return content:match "%[Http%w+%]"
    or content:match "%[Http%w+%("
    or content:match "%[Route%("
    or content:match "app%.Map%w+%("
    or content:match "endpoints%.Map%w+%("
    or content:match "%.%w+%([\"']"
    -- Also match controller method patterns without attributes
    or content:match "public%s+.*%s+%w+%s*%("
    or content:match "public%s+async%s+.*%s+%w+%s*%("
end

---Checks if content is inside a block comment or single line comment (basic check)
function DotNetParser:_is_commented_code(content, file_path, line_number)
  local trimmed = content:gsub("^%s+", "")

  -- Check for single line comments first
  if trimmed:match "^//" then
    return true
  end

  -- Check if line starts with /* or contains complete /* */ comment
  if trimmed:match "^/%*" or content:match "/%*.*%*/" then
    return true
  end

  -- Check if this looks like it's inside a comment block (starts with *)
  if trimmed:match "^%*" then
    return true
  end

  -- For multiline search results with file context, check if we're inside a /* */ block
  if file_path and line_number then
    local file = io.open(file_path, "r")
    if file then
      local lines = {}
      for line in file:lines() do
        table.insert(lines, line)
      end
      file:close()

      -- Look backwards to see if we're inside a comment block
      local in_comment_block = false
      for i = math.max(1, line_number - 20), line_number do
        if lines[i] then
          local line = lines[i]:gsub("^%s+", "")
          if line:match "^/%*" then
            in_comment_block = true
          elseif line:match "%*/%s*$" then
            in_comment_block = false
          elseif i == line_number and in_comment_block then
            return true
          end
        end
      end
    end
  else
    -- Without file context, do basic check
    return false
  end

  return false
end

---Calculates correct column position for attribute start
function DotNetParser:_calculate_attribute_column(content, file_path, line_number, ripgrep_column)
  -- ripgrep in multiline mode often returns column 1, so we need to calculate the actual position
  if ripgrep_column and ripgrep_column > 1 then
    return ripgrep_column -- Trust ripgrep if it gives a meaningful column
  end

  -- Read the actual line to find the attribute start position
  local file = io.open(file_path, "r")
  if not file then
    return 1
  end

  local current_line = 1
  for line in file:lines() do
    if current_line == line_number then
      file:close()
      -- Find the position of [ character (1-based)
      local bracket_pos = line:find("%[Http%w+") or line:find("%[Route%(") or line:find("app%.Map%w+%(") or line:find("endpoints%.Map%w+%(")
      if bracket_pos then
        return bracket_pos
      end
      break
    end
    current_line = current_line + 1
  end
  file:close()

  return 1 -- Fallback
end

---Extracts HTTP methods using multiline-aware extraction
function DotNetParser:_extract_methods_multiline(content, file_path, line_number)
  -- First try single line extraction
  local methods = {}
  local method = self:_extract_method_from_attributes(content)
  if method then
    table.insert(methods, method)
  end

  -- Check for multiple HTTP method attributes on same line/multiline block
  for http_method in content:gmatch "%[Http(%w+)%]" do
    if not vim.tbl_contains(methods, http_method) then
      table.insert(methods, http_method)
    end
  end

  for http_method in content:gmatch "%[Http(%w+)%(" do
    if not vim.tbl_contains(methods, http_method) then
      table.insert(methods, http_method)
    end
  end

  if #methods > 0 then
    return methods
  end

  -- If it's a multiline attribute, use the complete attribute content
  if self:_is_multiline_attribute(content) and file_path and line_number then
    local file = io.open(file_path, "r")
    if not file then
      return {}
    end

    local lines = {}
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()

    -- Read the attribute content across multiple lines
    local multiline_content = content
    for i = line_number + 1, math.min(line_number + 15, #lines) do
      local next_line = lines[i]
      if next_line then
        multiline_content = multiline_content .. " " .. next_line:gsub("^%s+", ""):gsub("%s+$", "")

        -- Try to extract methods from accumulated content
        local extracted_method = self:_extract_method_from_attributes(multiline_content)
        if extracted_method and not vim.tbl_contains(methods, extracted_method) then
          table.insert(methods, extracted_method)
        end

        -- Also check for additional HTTP method attributes
        for http_method in next_line:gmatch "%[Http(%w+)%]" do
          if not vim.tbl_contains(methods, http_method) then
            table.insert(methods, http_method)
          end
        end

        -- If we hit method declaration or closing parenthesis, stop
        if next_line:match "public%s+" or next_line:match "%s*%)%s*$" then
          break
        end
      end
    end
  end

  return methods
end

---Extracts route information from .NET patterns (multiline-aware)
function DotNetParser:_extract_route_info(content, file_path, line_number)
  -- For multiline attributes, we need to get the complete content first
  local full_content = content
  if self:_is_multiline_attribute(content) and file_path and line_number then
    local file = io.open(file_path, "r")
    if file then
      local lines = {}
      for line in file:lines() do
        table.insert(lines, line)
      end
      file:close()

      -- Read the next few lines to get the complete attribute
      for i = line_number + 1, math.min(line_number + 10, #lines) do
        local next_line = lines[i]
        if next_line then
          full_content = full_content .. " " .. next_line:gsub("^%s+", ""):gsub("%s+$", "")
          -- Stop when we hit the closing parenthesis
          if next_line:match "%s*%)%s*$" then
            break
          end
        end
      end
    end
  end

  -- Pattern 1: Attribute-based routing - [HttpGet("/path")]
  local method, path = full_content:match "%[Http(%w+)%([\"']([^\"']+)[\"']"
  if method and path then
    return method, path
  end

  -- Pattern 2: Attribute-based routing without path - [HttpGet] (only if no Route in same context)
  method = full_content:match "%[Http(%w+)%]"
  if method then
    -- Only process standalone HTTP methods if we're sure there's no Route attribute
    -- This will be handled by class-level Route logic
    return method, ""
  end

  -- Pattern 3: Minimal API - app.MapGet("/path", ...)
  method, path = full_content:match "app%.Map(%w+)%([\"']([^\"']+)[\"']"
  if method and path then
    return method, path
  end

  -- Pattern 4: Endpoint routing - endpoints.MapGet("/path", ...)
  method, path = full_content:match "endpoints%.Map(%w+)%([\"']([^\"']+)[\"']"
  if method and path then
    return method, path
  end

  -- Pattern 5: Route builder - .Get("/path")
  method, path = full_content:match "%.(%w+)%([\"']([^\"']+)[\"']"
  if method and path and method:match "^(Get|Post|Put|Delete|Patch)$" then
    return method, path
  end

  -- Pattern 6: [Route] attribute - process and get HTTP method from surrounding lines
  local route_path = content:match "%[Route%([\"']([^\"']+)[\"']"
  if route_path then
    -- Handle [controller] token replacement if file_path and line_number are provided
    if file_path and line_number and route_path:match "%[controller%]" then
      route_path = self:_replace_controller_token(route_path, file_path, line_number)
    end

    -- Check if there's an HTTP method attribute on the same line
    local http_method_match = content:match "%[Http(%w+)%]"
    if http_method_match then
      return http_method_match, route_path
    else
      -- If only [Route], default to GET - HTTP method will be determined later
      return "GET", route_path
    end
  end

  -- Pattern 7: Controller method without attributes (convention-based routing)
  local method_name = content:match "public%s+.*%s+(%w+)%s*%("
  if method_name then
    -- Map common controller method names to HTTP methods
    if method_name:match "^Get" or method_name:match "^Index" or method_name:match "^Details" then
      return "GET", ""
    elseif method_name:match "^Post" or method_name:match "^Create" then
      return "POST", ""
    elseif method_name:match "^Put" or method_name:match "^Update" or method_name:match "^Edit" then
      return "PUT", ""
    elseif method_name:match "^Delete" or method_name:match "^Remove" then
      return "DELETE", ""
    else
      -- Default to GET for other methods
      return "GET", ""
    end
  end

  return nil, nil
end

---Extracts path from .NET attributes
function DotNetParser:_extract_path_from_attributes(content)
  -- Try various attribute patterns
  local path = content:match "%[Http%w+%([\"']([^\"']+)[\"']"
  if path then
    return path
  end

  path = content:match "%[Route%([\"']([^\"']+)[\"']"
  if path then
    return path
  end

  path = content:match "app%.Map%w+%([\"']([^\"']+)[\"']"
  if path then
    return path
  end

  path = content:match "endpoints%.Map%w+%([\"']([^\"']+)[\"']"
  if path then
    return path
  end

  path = content:match "%.%w+%([\"']([^\"']+)[\"']"
  if path then
    return path
  end

  return nil
end

---Extracts HTTP method from surrounding lines
function DotNetParser:_extract_method_from_surrounding_lines(file_path, line_number)
  local file = io.open(file_path, "r")
  if not file then
    return nil
  end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  if #lines == 0 or line_number > #lines then
    return nil
  end

  -- Check current line and a few lines around it for HTTP method attributes
  local start_line = math.max(1, line_number - 3)
  local end_line = math.min(#lines, line_number + 3)

  for i = start_line, end_line do
    local line = lines[i]
    local method = self:_extract_method_from_attributes(line)
    if method then
      return method
    end
  end

  return nil
end

---Extracts method from .NET attributes
function DotNetParser:_extract_method_from_attributes(content)
  -- HTTP method attributes
  local method = content:match "%[Http(%w+)%]"
  if method then
    return method
  end

  method = content:match "%[Http(%w+)%("
  if method then
    return method
  end

  -- Minimal API patterns
  method = content:match "app%.Map(%w+)%("
  if method then
    return method
  end

  method = content:match "endpoints%.Map(%w+)%("
  if method then
    return method
  end

  -- Route builder patterns
  method = content:match "%.(%w+)%("
  if method and method:match "^(Get|Post|Put|Delete|Patch)$" then
    return method
  end

  return nil
end

---Detects the type of .NET attribute
function DotNetParser:_detect_attribute_type(content)
  if content:match "%[Http%w+" then
    return "http_attribute"
  elseif content:match "%[Route%(" then
    return "route_attribute"
  elseif content:match "app%.Map%w+%(" then
    return "minimal_api"
  elseif content:match "endpoints%.Map%w+%(" then
    return "endpoint_routing"
  elseif content:match "%.%w+%(" then
    return "route_builder"
  else
    return "unknown"
  end
end

---Checks if content has route template
function DotNetParser:_has_route_template(content)
  return content:match "[\"'][^\"']*%{[^}]+%}[^\"']*[\"']" ~= nil
end

---Gets controller base path from [Route] attribute or controller name
function DotNetParser:_get_controller_base_path(file_path, line_number)
  local file = io.open(file_path, "r")
  if not file then
    return ""
  end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  -- Look backwards from current line to find class declaration
  for i = line_number, 1, -1 do
    local line = lines[i]

    -- Check if this is a controller class declaration
    if line:match "class%s+%w+Controller" or line:match "class%s+%w+" then
      -- Look for [Route] attribute on this class or preceding lines
      for j = math.max(1, i - 10), i do
        local attr_line = lines[j]
        local route_path = attr_line:match "%[Route%([\"']([^\"']+)[\"']"
        if route_path then
          -- Handle [controller] token replacement
          if route_path:match "%[controller%]" then
            local controller_name = line:match "class%s+(%w+)Controller"
            if controller_name then
              local controller_lower = controller_name:gsub("^%u", string.lower):lower()
              route_path = route_path:gsub("%[controller%]", controller_lower)
            end
          end
          return route_path
        end

        -- Check for [ApiController] with [Route] pattern
        route_path = attr_line:match "%[Route%([\"']api/([^\"']+)[\"']"
        if route_path then
          return "/api/" .. route_path
        end
      end

      -- If no [Route] attribute found, derive from controller name
      local controller_name = line:match "class%s+(%w+)Controller"
      if controller_name then
        -- Convert PascalCase to lowercase
        local base_name = controller_name:gsub("^%u", string.lower)
        return "/" .. base_name:lower()
      end

      break
    end
  end

  return ""
end

---Replaces [controller] token with actual controller name
function DotNetParser:_replace_controller_token(route_path, file_path, line_number)
  local file = io.open(file_path, "r")
  if not file then
    return route_path
  end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  -- Look for class declaration around the given line
  for i = math.max(1, line_number - 10), math.min(#lines, line_number + 10) do
    local line = lines[i]
    local controller_name = line:match "class%s+(%w+)Controller"
    if controller_name then
      local controller_lower = controller_name:gsub("^%u", string.lower):lower()
      return route_path:gsub("%[controller%]", controller_lower)
    end
  end

  return route_path
end

---Combines base path with endpoint path
function DotNetParser:_combine_paths(base, endpoint)
  if not base or base == "" then
    return endpoint ~= "" and endpoint or "/"
  end
  if not endpoint or endpoint == "" then
    return base:match "^/" and base or "/" .. base
  end

  -- Handle special cases for .NET routing
  if endpoint:match "^%[action%]$" then
    -- [action] token - would need method name context
    return base .. "/{action}"
  end

  if endpoint:match "^%[controller%]" then
    -- [controller] token - already handled in base path
    return base
  end

  -- Ensure base starts with /
  if not base:match "^/" then
    base = "/" .. base
  end

  -- Remove trailing slash from base and leading slash from endpoint
  base = base:gsub("/$", "")
  endpoint = endpoint:gsub("^/", "")

  -- Handle root endpoint case
  if endpoint == "" then
    return base ~= "" and base or "/"
  end

  return base .. "/" .. endpoint
end

return DotNetParser
