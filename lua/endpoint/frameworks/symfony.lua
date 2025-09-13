---@class endpoint.frameworks.symfony
local M = {}

local fs = require "endpoint.utils.fs"

-- Detection
---@return boolean
function M.detect()
  -- Quick check for PHP project files first
  if not fs.has_file { "composer.json", "composer.lock" } then
    return false
  end

  -- Check for vendor/symfony directory (real projects)
  if fs.is_directory "vendor/symfony" then
    return true
  end

  -- Check composer.json content for symfony dependencies (fallback)
  if fs.file_contains("composer.json", "symfony") then
    return true
  end

  return false
end

-- Search command generation
---@param method string
---@return string
function M.get_search_cmd(method)
  local patterns = {
    GET = {
      "#\\[Route\\(.*methods.*GET", -- PHP 8+ attributes
      "@Route\\(.*methods.*GET", -- Direct annotations
      "\\* @Route\\(.*methods.*GET", -- Docblock annotations
    },
    POST = {
      "#\\[Route\\(.*methods.*POST",
      "@Route\\(.*methods.*POST",
      "\\* @Route\\(.*methods.*POST",
    },
    PUT = {
      "#\\[Route\\(.*methods.*PUT",
      "@Route\\(.*methods.*PUT",
      "\\* @Route\\(.*methods.*PUT",
    },
    DELETE = {
      "#\\[Route\\(.*methods.*DELETE",
      "@Route\\(.*methods.*DELETE",
      "\\* @Route\\(.*methods.*DELETE",
    },
    PATCH = {
      "#\\[Route\\(.*methods.*PATCH",
      "@Route\\(.*methods.*PATCH",
      "\\* @Route\\(.*methods.*PATCH",
    },
    ALL = {
      "#\\[Route\\(.*methods.*GET", -- PHP 8+ attributes GET
      "#\\[Route\\(.*methods.*POST", -- PHP 8+ attributes POST
      "#\\[Route\\(.*methods.*PUT", -- PHP 8+ attributes PUT
      "#\\[Route\\(.*methods.*DELETE", -- PHP 8+ attributes DELETE
      "#\\[Route\\(.*methods.*PATCH", -- PHP 8+ attributes PATCH
      "@Route\\(.*methods.*GET", -- Direct annotations GET
      "@Route\\(.*methods.*POST", -- Direct annotations POST
      "@Route\\(.*methods.*PUT", -- Direct annotations PUT
      "@Route\\(.*methods.*DELETE", -- Direct annotations DELETE
      "@Route\\(.*methods.*PATCH", -- Direct annotations PATCH
      "\\* @Route\\(.*methods.*GET", -- Docblock annotations GET
      "\\* @Route\\(.*methods.*POST", -- Docblock annotations POST
      "\\* @Route\\(.*methods.*PUT", -- Docblock annotations PUT
      "\\* @Route\\(.*methods.*DELETE", -- Docblock annotations DELETE
      "\\* @Route\\(.*methods.*PATCH", -- Docblock annotations PATCH
    },
  }

  -- Use utility function for search command generation
  local search_utils = require "endpoint.utils.search"
  local search_cmd_generator = search_utils.create_search_cmd_generator(
    patterns,
    search_utils.common_globs.php,
    { "**/vendor", "**/var" }, -- Symfony-specific excludes  
    { "--case-sensitive" } -- Symfony routes are case-sensitive
  )

  return search_cmd_generator(method)
end

-- Line parsing - can return multiple endpoints for multiple methods
---@param line string
---@param method string
---@return endpoint.entry|endpoint.entry[]|nil
function M.parse_line(line, method)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    return nil
  end

  -- Skip controller-level @Route (without methods parameter)
  if M.is_controller_level_route(content) then
    return nil
  end

  -- Extract endpoint path
  local endpoint_path = M.extract_path(content)
  if not endpoint_path then
    return nil
  end

  -- Try to get base path from controller-level @Route
  local base_path = M.get_base_path(file_path, tonumber(line_number))
  local full_path = M.combine_paths(base_path, endpoint_path)

  -- Extract HTTP methods (can be multiple)
  local parsed_methods = M.extract_methods(content, method)

  -- Return multiple endpoints if multiple methods
  if #parsed_methods > 1 then
    local endpoints = {}
    for _, parsed_method in ipairs(parsed_methods) do
      table.insert(endpoints, {
        file_path = file_path,
        line_number = tonumber(line_number),
        column = tonumber(column),
        method = parsed_method,
        endpoint_path = full_path,
        display_value = parsed_method .. " " .. full_path,
      })
    end
    return endpoints
  else
    return {
      file_path = file_path,
      line_number = tonumber(line_number),
      column = tonumber(column),
      method = parsed_methods[1] or "GET",
      endpoint_path = full_path,
      display_value = (parsed_methods[1] or "GET") .. " " .. full_path,
    }
  end
end

-- Extract path from Symfony Route annotations/attributes
---@param content string
---@return string|nil
function M.extract_path(content)
  -- #[Route('/path', methods: ['GET'])] (PHP 8 attributes)
  local path = content:match "#%[Route%(%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  -- @Route("/path", methods={"GET"}) (direct annotations)
  path = content:match "@Route%(%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  -- * @Route("/path", methods={"GET"}) (docblock annotations)
  path = content:match "\\* @Route%(%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  return nil
end

-- Extract HTTP methods (can be multiple)
---@param content string
---@param search_method string
---@return string[]
function M.extract_methods(content, search_method)
  -- Handle case where search_method is not provided
  if not search_method then
    search_method = "ALL"
  end

  -- If searching for specific method, return it
  if search_method ~= "ALL" then
    return { search_method:upper() }
  end

  local methods = {}

  -- Extract all methods from various formats
  -- methods={"GET", "POST"} or methods: ['GET', 'POST'] or methods={GET, POST}
  local methods_section = content:match "methods[^%[%{]*([%[%{][^%]%}]*[%]%}])"
  if methods_section then
    -- Extract all method names within brackets
    for method in methods_section:gmatch "[\"']?([A-Z]+)[\"']?" do
      if method:match "^[A-Z]+$" then -- Only HTTP methods (all caps)
        table.insert(methods, method:upper())
      end
    end
  end

  -- If no methods found, default to GET
  if #methods == 0 then
    table.insert(methods, "GET")
  end

  return methods
end

-- Extract single HTTP method (backward compatibility)
---@param content string
---@param search_method string
---@return string
function M.extract_method(content, search_method)
  local methods = M.extract_methods(content, search_method)
  return methods[1] or "GET"
end

-- Check if this is a controller-level @Route (no methods parameter)
---@param content string
---@return boolean
function M.is_controller_level_route(content)
  -- If it contains methods parameter, it's a method-level route
  if content:match "methods" then
    return false
  end

  -- Check for @Route without methods parameter
  if content:match "@Route%s*%(" or content:match "#%[Route%(" or content:match "\\* @Route%s*%(" then
    return true
  end

  return false
end

-- Get base path from controller-level @Route
---@param file_path string
---@param line_number number|nil
---@return string
function M.get_base_path(file_path, line_number)
  -- Handle case where line_number is not provided
  if not line_number then
    line_number = math.huge -- Read entire file if no line number provided
  end

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

  -- Look backwards for controller-level @Route
  for i = math.min(line_number, #lines), 1, -1 do
    local line = lines[i]

    -- Check if this is a class declaration
    if line:match "class%s+%w+" then
      -- Look for @Route on this class or preceding lines (including docblocks)
      for j = math.max(1, i - 10), i do
        local annotation_line = lines[j]

        -- Check for various @Route patterns
        local base_path = annotation_line:match "#%[Route%(%s*[\"']([^\"']+)[\"']" -- PHP 8+ attributes
        if base_path then
          return base_path
        end

        base_path = annotation_line:match "@Route%(%s*[\"']([^\"']+)[\"']" -- Direct annotations
        if base_path then
          return base_path
        end

        base_path = annotation_line:match "\\* @Route%(%s*[\"']([^\"']+)[\"']" -- Docblock annotations
        if base_path then
          return base_path
        end
      end
      break
    end
  end

  return ""
end

-- Combine base path with endpoint path
---@param base string|nil
---@param endpoint string|nil
---@return string
function M.combine_paths(base, endpoint)
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

return M
