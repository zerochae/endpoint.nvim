-- .NET Framework Utility Functions
---@class endpoint.frameworks.dotnet.utils
local M = {}

-- Extract route information from .NET patterns
---@param content string
---@param search_method string
---@return string?, string?
function M.extract_route_info(content, search_method)
  -- Pattern 1: Attribute-based routing - [HttpGet("/path")]
  local method, path = content:match "%[Http(%w+)%([\"']([^\"']+)[\"']"
  if method and path then
    return method:upper(), path
  end

  -- Pattern 2: Attribute-based routing without path - [HttpGet]
  method = content:match "%[Http(%w+)%]"
  if method then
    -- Path will be determined from action name or controller routing
    return method:upper(), ""
  end

  -- Pattern 3: Minimal API - app.MapGet("/path", ...)
  method, path = content:match "app%.Map(%w+)%([\"']([^\"']+)[\"']"
  if method and path then
    return method:upper(), path
  end

  -- Pattern 4: Endpoint routing - endpoints.MapGet("/path", ...)
  method, path = content:match "endpoints%.Map(%w+)%([\"']([^\"']+)[\"']"
  if method and path then
    return method:upper(), path
  end

  -- Pattern 5: Route builder - .Get("/path")
  method, path = content:match "%.(%w+)%([\"']([^\"']+)[\"']"
  if method and path and method:match "^(Get|Post|Put|Delete|Patch)$" then
    return method:upper(), path
  end

  -- Pattern 6: [Route] attribute with [HttpGet] on same or next line
  if content:match "%[Route%([\"']([^\"']+)[\"']" then
    local route_path = content:match "%[Route%([\"']([^\"']+)[\"']"
    if route_path then
      -- Check if there's also an Http method on the same line
      local http_method_match = content:match "%[Http(%w+)%]"
      if http_method_match then
        return http_method_match:upper(), route_path
      end
      -- Otherwise, we'll need to look at surrounding lines
      return nil, nil
    end
  end

  -- If no pattern matches but we're searching for a specific method,
  -- try to extract from method name patterns
  if search_method ~= "ALL" then
    local search_lower = search_method:lower()
    if content:match("%[Http" .. search_method .. "%]") or content:match("Map" .. search_method .. "%(") then
      return search_method:upper(), ""
    end
  end

  return nil, nil
end

-- Get base path from controller-level [Route] attribute or controller name
---@param file_path string
---@param line_number number
---@return string
function M.get_base_path(file_path, line_number)
  -- Read file content to find controller-level route
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
        -- Convert PascalCase to lowercase with potential pluralization
        local base_name = controller_name:gsub("^%u", string.lower)
        return "/" .. base_name:lower()
      end

      break
    end
  end

  return ""
end

-- Combine base path with endpoint path
---@param base string
---@param endpoint string
---@return string
function M.combine_paths(base, endpoint)
  if not base or base == "" then
    return endpoint ~= "" and endpoint or "/"
  end
  if not endpoint or endpoint == "" then
    return base:match("^/") and base or "/" .. base
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
  if not base:match("^/") then
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

return M