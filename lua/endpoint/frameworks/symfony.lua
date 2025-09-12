-- Symfony Framework Implementation (Function-based)
local M = {}

-- Detection
function M.detect()
  -- Check for composer.json first
  if vim.fn.filereadable "composer.json" == 0 then
    return false
  end

  -- Check for vendor/symfony directory (real projects)
  if vim.fn.isdirectory "vendor/symfony" == 1 then
    return true
  end

  -- Check composer.json content for symfony dependencies (fallback)
  local composer_file = io.open("composer.json", "r")
  if composer_file then
    local content = composer_file:read "*all"
    composer_file:close()

    if content and content:match "symfony" then
      return true
    end
  end

  return false
end

-- Search command generation
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
      "#\\[Route", -- PHP 8+ attributes
      "@Route", -- Direct annotations
      "\\* @Route", -- Docblock annotations
    },
  }

  local method_patterns = patterns[method:upper()] or patterns.ALL

  local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"
  cmd = cmd .. " --glob '**/*.php'"
  cmd = cmd .. " --glob '!**/vendor/**'"
  cmd = cmd .. " --glob '!**/var/**'"

  -- Add patterns
  for _, pattern in ipairs(method_patterns) do
    cmd = cmd .. " -e '" .. pattern .. "'"
  end

  return cmd
end

-- Line parsing - can return multiple endpoints for multiple methods
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
function M.extract_methods(content, search_method)
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
function M.extract_method(content, search_method)
  local methods = M.extract_methods(content, search_method)
  return methods[1] or "GET"
end

-- Check if this is a controller-level @Route (no methods parameter)
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
function M.get_base_path(file_path, line_number)
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
function M.combine_paths(base, endpoint)
  if not base or base == "" then
    return endpoint
  end
  if not endpoint or endpoint == "" then
    return base
  end

  -- Remove trailing slash from base and leading slash from endpoint
  base = base:gsub("/$", "")
  endpoint = endpoint:gsub("^/", "")

  return base .. "/" .. endpoint
end

return M

