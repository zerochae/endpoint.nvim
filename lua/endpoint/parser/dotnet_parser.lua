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
  -- Use _extract_route_info for better accuracy
  local http_method, endpoint_path = self:_extract_route_info(content, file_path, line_number)
  if endpoint_path then
    -- If the path starts with '/', it's an absolute path and shouldn't be combined with base path
    if endpoint_path:match("^/") then
      return endpoint_path
    else
      return endpoint_path
    end
  end

  -- Fallback to attribute extraction
  local path = self:_extract_path_from_attributes(content)
  if path then
    -- Same logic for fallback path
    if path:match("^/") then
      return path
    else
      return path
    end
  end

  return nil
end

---Extracts HTTP method from .NET attribute content
function DotNetParser:extract_method(content, file_path, line_number)
  local method = self:_extract_method_from_attributes(content)
  if method then
    return method:upper()
  end

  -- If no method found in current line and we have file context, check surrounding lines
  if file_path and line_number then
    method = self:_extract_method_from_surrounding_lines(file_path, line_number)
    if method then
      return method:upper()
    end
  end

  return "GET" -- Default fallback
end

---Override parse_content to add .NET-specific metadata and handle absolute paths
function DotNetParser:parse_content(content, file_path, line_number, column)
  -- Only process if this looks like .NET attribute content
  if not self:is_content_valid_for_parsing(content) then
    return nil
  end

  local endpoint_path = self:extract_endpoint_path(content, file_path, line_number)
  local method = self:extract_method(content, file_path, line_number)

  -- Require both endpoint path and method to be present
  if not endpoint_path or not method then
    return nil
  end

  -- If endpoint path is empty, check if there's a class-level Route attribute
  if not endpoint_path or endpoint_path == "" then
    -- For HTTP method attributes without explicit paths, check if there's a meaningful base path
    local base_path = self:extract_base_path(file_path, line_number)
    if base_path and base_path ~= "" then
      -- Only use base path if it contains actual route information (not just controller name)
      if base_path:match("^api/") or base_path:match("^/api/") then
        endpoint_path = base_path  -- Use controller base path
      else
        return nil  -- Base path is just controller name, not useful for routing
      end
    else
      return nil  -- No route information available
    end
  end

  -- Handle path combination logic
  local final_path
  if endpoint_path:match("^/") then
    -- Absolute path - use as is
    final_path = endpoint_path
  elseif endpoint_path:match("^api/") then
    -- Path starting with api/ - treat as absolute
    final_path = "/" .. endpoint_path
  else
    -- Relative path - combine with base path
    local base_path = self:extract_base_path(file_path, line_number)

    -- If endpoint_path is the same as base_path, don't combine
    if endpoint_path == base_path then
      final_path = "/" .. endpoint_path
    else
      final_path = self:_combine_paths(base_path, endpoint_path)
    end
  end

  local endpoint = {
    method = method:upper(),
    endpoint_path = final_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = method:upper() .. " " .. final_path,
    confidence = self:get_parsing_confidence(content),
    tags = { "csharp", "dotnet", "attribute" },
    metadata = self:create_metadata("attribute", {
      attribute_type = self:_detect_attribute_type(content),
      has_route_template = self:_has_route_template(content),
    }, content),
  }

  return endpoint
end

---Validates if content contains .NET attributes
function DotNetParser:is_content_valid_for_parsing(content)
  if not Parser.is_content_valid_for_parsing(self, content) then
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

---Extracts route information from .NET patterns
function DotNetParser:_extract_route_info(content, file_path, line_number)
  -- Pattern 1: Attribute-based routing - [HttpGet("/path")]
  local method, path = content:match "%[Http(%w+)%([\"']([^\"']+)[\"']"
  if method and path then
    return method, path
  end

  -- Pattern 2: Attribute-based routing without path - [HttpGet] (only if no Route in same context)
  method = content:match "%[Http(%w+)%]"
  if method then
    -- Only process standalone HTTP methods if we're sure there's no Route attribute
    -- This will be handled by class-level Route logic
    return method, ""
  end

  -- Pattern 3: Minimal API - app.MapGet("/path", ...)
  method, path = content:match "app%.Map(%w+)%([\"']([^\"']+)[\"']"
  if method and path then
    return method, path
  end

  -- Pattern 4: Endpoint routing - endpoints.MapGet("/path", ...)
  method, path = content:match "endpoints%.Map(%w+)%([\"']([^\"']+)[\"']"
  if method and path then
    return method, path
  end

  -- Pattern 5: Route builder - .Get("/path")
  method, path = content:match "%.(%w+)%([\"']([^\"']+)[\"']"
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

