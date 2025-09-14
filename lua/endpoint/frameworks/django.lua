---@class endpoint.frameworks.django
local M = {}

local fs = require "endpoint.utils.fs"

-- Django framework detection
---@return boolean
function M.detect()
  -- Primary indicator: Django projects always have manage.py
  if fs.has_file { "manage.py" } then
    return true
  end

  -- Secondary check: settings files in common locations
  if fs.has_file { "settings.py", "*/settings.py", "*/settings/__init__.py" } then
    return true
  end

  -- Tertiary check: Django dependencies
  if fs.file_contains("requirements.txt", "django") or fs.file_contains("pyproject.toml", "django") then
    return true
  end

  return false
end

-- Create search command generator focusing on URL patterns and view functions
local search_utils = require "endpoint.utils.search"
local get_search_cmd = search_utils.create_search_cmd_generator(
  {
    -- Focus only on view implementations, not URL patterns
    GET = {
      "def\\s+get\\s*\\(",  -- HTTP method implementations in views
      "def\\s+retrieve\\s*\\(",  
      "def\\s+list\\s*\\(",
    },
    POST = {
      "def\\s+post\\s*\\(",
      "def\\s+create\\s*\\(",
    },
    PUT = {
      "def\\s+put\\s*\\(",
      "def\\s+update\\s*\\(",
    },
    DELETE = {
      "def\\s+delete\\s*\\(",
      "def\\s+destroy\\s*\\(",
    },
    PATCH = {
      "def\\s+patch\\s*\\(",
      "def\\s+partial_update\\s*\\(",
    },
    ALL = {
      "def\\s+get\\s*\\(",
      "def\\s+post\\s*\\(",
      "def\\s+put\\s*\\(",
      "def\\s+patch\\s*\\(",
      "def\\s+delete\\s*\\(",
      "def\\s+create\\s*\\(",
      "def\\s+update\\s*\\(",
      "def\\s+destroy\\s*\\(",
      "def\\s+list\\s*\\(",
      "def\\s+retrieve\\s*\\(",
      "def\\s+partial_update\\s*\\(",
    },
  },
  { "**/views.py", "**/viewsets.py" }, -- Only search in view files
  { "**/migrations", "**/__pycache__", "**/venv", "**/env", "**/node_modules", "**/urls.py" }, -- Exclude URL files
  { "--type", "py" } -- Additional ripgrep flags
)

-- Search command generation
---@param method string
---@return string
function M.get_search_cmd(method)
  return get_search_cmd(method)
end

-- Parse ripgrep output line
---@param line string
---@param method string
---@return endpoint.entry?
function M.parse_line(line, method)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    return nil
  end

  -- Extract HTTP method and path from Django patterns
  local http_method, endpoint_path = M.extract_route_info(content, method, file_path, tonumber(line_number))
  if not http_method or not endpoint_path then
    return nil
  end

  return {
    method = http_method,
    endpoint_path = endpoint_path,
    file_path = file_path,
    line_number = tonumber(line_number),
    column = tonumber(column),
    display_value = http_method .. " " .. endpoint_path,
  }
end

-- Extract route information from Django patterns
---@param content string
---@param search_method string
---@param file_path string
---@param line_number number
---@return string?, string?
function M.extract_route_info(content, search_method, file_path, line_number)
  -- Debug logging
  if os.getenv("DEBUG_DJANGO") then
    print(string.format("[Django Debug] extract_route_info called: content='%s', method='%s', file='%s', line=%d", 
          content:gsub("%s+", " "), search_method, file_path, line_number))
  end
  
  -- Skip URL pattern definitions in urls.py files - we want actual view implementations
  if file_path:match "urls%.py$" then
    if os.getenv("DEBUG_DJANGO") then
      print("[Django Debug] Skipping urls.py file")
    end
    return nil, nil
  end

  -- Pattern 1: HTTP method implementations in Class-based views and ViewSets
  local method_name
  if content:match "^%s*def%s+get%s*%(" then
    method_name = "get"
  elseif content:match "^%s*def%s+post%s*%(" then
    method_name = "post"
  elseif content:match "^%s*def%s+put%s*%(" then
    method_name = "put"
  elseif content:match "^%s*def%s+patch%s*%(" then
    method_name = "patch"
  elseif content:match "^%s*def%s+delete%s*%(" then
    method_name = "delete"
  elseif content:match "^%s*def%s+list%s*%(" then
    method_name = "list"
  elseif content:match "^%s*def%s+create%s*%(" then
    method_name = "create"
  elseif content:match "^%s*def%s+retrieve%s*%(" then
    method_name = "retrieve"
  elseif content:match "^%s*def%s+update%s*%(" then
    method_name = "update"
  elseif content:match "^%s*def%s+destroy%s*%(" then
    method_name = "destroy"
  elseif content:match "^%s*def%s+partial_update%s*%(" then
    method_name = "partial_update"
  end
  if os.getenv("DEBUG_DJANGO") then
    print(string.format("[Django Debug] Pattern 1 - method_name='%s'", method_name or "nil"))
  end
  if method_name and file_path:match "views%.py$" then
    local http_method = M.convert_to_http_method(method_name)
    
    -- Find the parent class to get the actual URL
    local class_name = M.find_parent_class(file_path, line_number)
    if class_name then
      -- Try to find URL for this class-based view
      local url_path = M.find_url_for_view(class_name, file_path)
      if url_path then
        return http_method, url_path
      end
      
      -- Fallback to building URL from class name and app
      local fallback_url = M.build_fallback_url(class_name:lower(), file_path)
      return http_method, fallback_url
    else
      -- Method without class (shouldn't happen but handle gracefully)
      local fallback_url = M.build_fallback_url(method_name, file_path)
      return http_method, fallback_url
    end
  end

  -- Pattern 2: Function-based views in views.py  
  local function_name = content:match "^%s*def%s+([%w_]+)%s*%("
  if function_name and file_path:match "views%.py$" then
    -- Skip Django built-in HTTP method handlers (already handled above)
    if function_name:match "^(get|post|put|patch|delete|head|options|trace)$" then
      return nil, nil
    end

    -- Try to find actual URL mapping
    local url_path = M.find_url_for_function(function_name, file_path)

    if url_path then
      -- Found actual URL pattern, determine HTTP method from function analysis
      local methods = M.analyze_function_view_methods(function_name, file_path, line_number)
      
      -- For ALL search, return the first supported method
      if search_method == "ALL" then
        if #methods > 0 then
          return methods[1], url_path
        else
          return "GET", url_path -- Default fallback
        end
      -- For specific method search, only return if function supports it
      elseif vim.tbl_contains(methods, search_method) then
        return search_method, url_path
      else
        -- Function doesn't support the searched HTTP method
        return nil, nil
      end
    end

    -- No URL mapping found - skip to avoid placeholder URLs
    return nil, nil
  end

  -- Pattern 3: Class-based view and ViewSet definitions
  local class_name = content:match "^%s*class%s+([%w_]+)%s*%("
  if class_name and (file_path:match "views%.py$" or file_path:match "viewsets%.py$") then
    -- Handle ViewSets differently from regular views
    if file_path:match "viewsets%.py$" or class_name:match "ViewSet$" then
      -- For ViewSets, try to find router registration
      local urls = M.find_router_urls_for_viewset(class_name, file_path)
      if #urls > 0 then
        local methods = M.analyze_viewset_methods(class_name, file_path, line_number)
        local http_method = M.select_primary_method(methods, search_method)
        return http_method, urls[1] -- Return first URL
      else
        -- Fallback for ViewSet
        return "GET", "/api/viewset"
      end
    else
      -- Regular class-based view
      local url_path = M.find_url_for_view(class_name, file_path)
      
      if url_path then
        -- Determine HTTP method based on view type
        local methods = M.analyze_view_methods(class_name, file_path)
        local http_method = M.select_primary_method(methods, search_method)
        return http_method, url_path
      else
        -- Fallback - create URL from class name
        local fallback_url = M.build_fallback_url(class_name:lower():gsub("view$", ""), file_path)
        return "GET", fallback_url
      end
    end
  end

  return nil, nil
end

-- Normalize Django URL path patterns
---@param path string
---@return string
function M.normalize_django_path(path)
  if not path then
    return "/"
  end

  -- Remove regex anchors
  path = path:gsub("^%^", ""):gsub("%$$", "")

  -- Convert Django path parameters <type:name> to {name}
  path = path:gsub("<([^:>]+):([^>]+)>", "{%2}")

  -- Convert regex named groups (?P<name>pattern) to {name}
  path = path:gsub("%(%?P<([^>]+)>[^)]*%)", "{%1}")

  -- Ensure path starts with /
  if not path:match "^/" then
    path = "/" .. path
  end

  -- Remove trailing slash for consistency (except root)
  if path ~= "/" and path:match "/$" then
    path = path:gsub("/$", "")
  end

  return path
end

-- Detect HTTP methods supported by a URL pattern
---@param file_path string
---@param line_number number
---@param content string
---@return string[]
function M.detect_http_methods_for_url(file_path, line_number, content)
  local methods = {}

  -- Check if it's pointing to a view function/class
  local view_name = content:match "views%.([%w_]+)" or content:match "([%w_]+)%.as_view"

  if view_name then
    -- Try to find the view definition and analyze its methods
    local view_methods = M.analyze_view_methods(view_name, file_path)
    for _, method in ipairs(view_methods) do
      table.insert(methods, method)
    end
  end

  -- Default assumption for URL patterns
  if #methods == 0 then
    methods = { "GET" }
  end

  return methods
end

-- Analyze what HTTP methods a view supports
---@param view_name string
---@param urls_file_path string
---@return string[]
function M.analyze_view_methods(view_name, urls_file_path)
  local methods = {}

  -- Find views.py file relative to urls.py
  local views_file = urls_file_path:gsub("urls%.py$", "views.py")

  if vim.fn.filereadable(views_file) == 1 then
    local content = vim.fn.readfile(views_file)
    local in_view = false
    local in_class = false
    local class_name = ""

    for _, line in ipairs(content) do
      -- Function-based view
      if line:match("def%s+" .. view_name .. "%s*%(") then
        in_view = true
      end

      -- Class-based view
      if line:match("class%s+" .. view_name) then
        in_class = true
        class_name = view_name
      end

      -- Check for HTTP method definitions in class
      if in_class and line:match "def%s+(get|post|put|patch|delete)%s*%(" then
        local method = line:match "def%s+([%w]+)%s*%("
        if method then
          table.insert(methods, method:upper())
        end
      end

      -- End of class
      if in_class and line:match "^class%s+" and not line:match(class_name) then
        in_class = false
      end
    end
  end

  -- Default methods for common view types
  if #methods == 0 then
    if view_name:match "List" then
      methods = { "GET", "POST" }
    elseif view_name:match "Detail" then
      methods = { "GET", "PUT", "PATCH", "DELETE" }
    elseif view_name:match "Create" then
      methods = { "POST" }
    elseif view_name:match "Update" then
      methods = { "PUT", "PATCH" }
    elseif view_name:match "Delete" then
      methods = { "DELETE" }
    else
      methods = { "GET" }
    end
  end

  return methods
end

-- Extract HTTP methods from class-based view
---@param class_name string
---@param file_path string
---@param line_number number
---@return string[]
function M.extract_methods_from_cbv(class_name, file_path, line_number)
  return M.analyze_view_methods(class_name, file_path)
end

-- Find URL pattern for a specific view class
---@param view_name string
---@param current_file string
---@return string?
function M.find_url_for_view(view_name, current_file)
  if current_file:match "views%.py$" then
    local urls_file = current_file:gsub("views%.py$", "urls.py")
    if vim.fn.filereadable(urls_file) == 1 then
      local content = vim.fn.readfile(urls_file)
      
      -- Determine app prefix
      local app_name = current_file:match "([%w_]+)/views%.py$"
      local app_prefix = ""
      if app_name then
        local main_urls_files = {
          "myproject/urls.py",
          "*/urls.py", 
          "urls.py"
        }
        
        for _, main_urls_pattern in ipairs(main_urls_files) do
          if main_urls_pattern:match "%*" then
            local possible_files = vim.fn.glob(main_urls_pattern, false, true)
            for _, main_urls_file in ipairs(possible_files) do
              local main_content = vim.fn.readfile(main_urls_file)
              app_prefix = M.extract_app_prefix(main_content, app_name)
              if app_prefix ~= "" then break end
            end
          else
            if vim.fn.filereadable(main_urls_pattern) == 1 then
              local main_content = vim.fn.readfile(main_urls_pattern)
              app_prefix = M.extract_app_prefix(main_content, app_name)
            end
          end
          if app_prefix ~= "" then break end
        end
      end
      
      -- Look for view class reference
      for _, line in ipairs(content) do
        if line:match(view_name) then
          local path = line:match "path%s*%(%s*['\"]([^'\"]+)['\"]"
          if path then
            local normalized_path = M.normalize_django_path(path)
            return app_prefix .. normalized_path
          end
        end
      end
    end
  end
  return nil
end

-- Find URL pattern for a function-based view
---@param function_name string
---@param file_path string
---@return string?
function M.find_url_for_function(function_name, file_path)
  -- Look for URL patterns that reference this function
  if file_path:match "views%.py$" then
    local urls_file = file_path:gsub("views%.py$", "urls.py")
    if vim.fn.filereadable(urls_file) == 1 then
      local content = vim.fn.readfile(urls_file)
      
      -- First, determine app prefix by looking at the app structure
      local app_name = file_path:match "([%w_]+)/views%.py$"
      local app_prefix = ""
      if app_name then
        -- Check main project urls.py for app inclusion  
        local main_urls_files = {
          "myproject/urls.py",
          "*/urls.py", 
          "urls.py"
        }
        
        for _, main_urls_pattern in ipairs(main_urls_files) do
          -- Handle glob patterns
          if main_urls_pattern:match "%*" then
            local possible_files = vim.fn.glob(main_urls_pattern, false, true)
            for _, main_urls_file in ipairs(possible_files) do
              local main_content = vim.fn.readfile(main_urls_file)
              app_prefix = M.extract_app_prefix(main_content, app_name)
              if app_prefix ~= "" then break end
            end
          else
            if vim.fn.filereadable(main_urls_pattern) == 1 then
              local main_content = vim.fn.readfile(main_urls_pattern)
              app_prefix = M.extract_app_prefix(main_content, app_name)
            end
          end
          if app_prefix ~= "" then break end
        end
      end
      
      -- Now look for the specific function in app's urls.py
      for _, line in ipairs(content) do
        if line:match("views%." .. function_name) then
          local path = line:match "path%s*%(%s*['\"]([^'\"]*)['\"]"
            or line:match "re_path%s*%(%s*r?['\"]([^'\"]+)['\"]"
            or line:match "url%s*%(%s*r?['\"]([^'\"]+)['\"]"
          if path then
            local normalized_path = M.normalize_django_path(path)
            -- Combine app prefix with path
            if normalized_path == "/" then
              return app_prefix == "" and "/" or app_prefix
            else
              return app_prefix .. normalized_path
            end
          end
        end
      end
    end
  end
  return nil
end

-- Extract app prefix from main urls.py content
---@param main_content string[]
---@param app_name string
---@return string
function M.extract_app_prefix(main_content, app_name)
  for _, main_line in ipairs(main_content) do
    -- Look for path('prefix/', include('app.urls'))
    if main_line:match(app_name .. "%.urls") then
      local prefix = main_line:match "path%s*%(%s*['\"]([^'\"]*)['\"]"
      if prefix then
        return "/" .. prefix:gsub("/$", "") -- Remove trailing slash, ensure leading slash
      end
    end
  end
  return ""
end

-- Find URL pattern for a ViewSet
---@param viewset_name string
---@param file_path string
---@return string?
function M.find_url_for_viewset(viewset_name, file_path)
  -- ViewSets are typically registered with routers
  -- This would need to parse router.register() calls
  return "/api/viewset" -- Placeholder
end

-- Select primary HTTP method from a list of methods, preferring the search method
---@param methods string[]
---@param search_method string
---@return string
function M.select_primary_method(methods, search_method)
  if #methods == 0 then
    return "GET" -- Default fallback
  end

  -- Prefer the search method if found
  for _, method in ipairs(methods) do
    if method == search_method then
      return method
    end
  end

  -- Return the first method found
  return methods[1]
end

-- Analyze function-based view methods by examining the function body
---@param function_name string
---@param file_path string
---@param line_number number
---@return string[]
function M.analyze_function_view_methods(function_name, file_path, line_number)
  local methods = {}

  if vim.fn.filereadable(file_path) == 1 then
    local content = vim.fn.readfile(file_path)
    local in_function = false
    local brace_level = 0

    for i = line_number, #content do
      local line = content[i]

      -- Start of our function
      if line:match("def%s+" .. function_name .. "%s*%(") then
        in_function = true
      end

      -- End of function (next def or class at same level)
      if in_function and line:match "^def%s+" and not line:match("def%s+" .. function_name) then
        break
      end
      if in_function and line:match "^class%s+" then
        break
      end

      -- Look for HTTP method handling inside the function
      if in_function then
        if line:match "request%.method%s*==%s*['\"]GET['\"]" or line:match "if.*GET" then
          table.insert(methods, "GET")
        end
        if line:match "request%.method%s*==%s*['\"]POST['\"]" or line:match "elif.*POST" then
          table.insert(methods, "POST")
        end
        if line:match "request%.method%s*==%s*['\"]PUT['\"]" or line:match "elif.*PUT" then
          table.insert(methods, "PUT")
        end
        if line:match "request%.method%s*==%s*['\"]PATCH['\"]" or line:match "elif.*PATCH" then
          table.insert(methods, "PATCH")
        end
        if line:match "request%.method%s*==%s*['\"]DELETE['\"]" or line:match "elif.*DELETE" then
          table.insert(methods, "DELETE")
        end
      end
    end
  end

  -- Default based on function name patterns
  if #methods == 0 then
    if function_name:match "list" or function_name:match "get" or function_name:match "detail" then
      methods = { "GET" }
    elseif function_name:match "create" or function_name:match "add" then
      methods = { "POST" }
    elseif function_name:match "update" then
      methods = { "PUT", "PATCH" }
    elseif function_name:match "delete" or function_name:match "remove" then
      methods = { "DELETE" }
    else
      methods = { "GET" } -- Default fallback
    end
  end

  return methods
end

-- Analyze ViewSet methods and actions
---@param viewset_name string
---@param file_path string
---@param line_number number
---@return string[]
function M.analyze_viewset_methods(viewset_name, file_path, line_number)
  local methods = {}

  if vim.fn.filereadable(file_path) == 1 then
    local content = vim.fn.readfile(file_path)
    local in_viewset = false

    for i = line_number, #content do
      local line = content[i]

      -- Start of ViewSet class
      if line:match("class%s+" .. viewset_name) then
        in_viewset = true
      end

      -- End of ViewSet class (next class at same level)
      if in_viewset and line:match "^class%s+" and not line:match("class%s+" .. viewset_name) then
        break
      end

      -- Look for ViewSet action methods
      if in_viewset then
        if line:match "def%s+list%s*%(" then
          table.insert(methods, "GET")
        elseif line:match "def%s+create%s*%(" then
          table.insert(methods, "POST")
        elseif line:match "def%s+retrieve%s*%(" then
          table.insert(methods, "GET")
        elseif line:match "def%s+update%s*%(" then
          table.insert(methods, "PUT")
        elseif line:match "def%s+partial_update%s*%(" then
          table.insert(methods, "PATCH")
        elseif line:match "def%s+destroy%s*%(" then
          table.insert(methods, "DELETE")
        end
      end
    end
  end

  -- Default ViewSet methods if none found
  if #methods == 0 then
    methods = { "GET", "POST", "PUT", "PATCH", "DELETE" }
  end

  return methods
end

-- Find router URLs for ViewSet (simplified implementation)
---@param viewset_name string
---@param file_path string
---@return string[]
function M.find_router_urls_for_viewset(viewset_name, file_path)
  local urls = {}

  -- Look for router.register() calls in urls.py files
  local main_urls_files = {
    "myproject/urls.py",
    "*/urls.py", 
    "urls.py"
  }

  for _, main_urls_pattern in ipairs(main_urls_files) do
    local possible_files = {}
    if main_urls_pattern:match "%*" then
      possible_files = vim.fn.glob(main_urls_pattern, false, true)
    else
      if vim.fn.filereadable(main_urls_pattern) == 1 then
        table.insert(possible_files, main_urls_pattern)
      end
    end

    for _, urls_file in ipairs(possible_files) do
      local content = vim.fn.readfile(urls_file)
      local router_prefix = ""
      local viewset_route_prefix = ""

      for _, line in ipairs(content) do
        -- Find router inclusion: path('api/v1/', include(router.urls))
        if line:match "router%.urls" then
          router_prefix = line:match "path%s*%(%s*['\"]([^'\"]*)['\"]" or ""
        end
        
        -- Find ViewSet registration: router.register('prefix', ViewSetName)
        if line:match "router%.register" and line:match(viewset_name) then
          viewset_route_prefix = line:match "router%.register%s*%(%s*r?['\"]([^'\"]+)['\"]" or ""
          break
        end
      end

      if router_prefix ~= "" and viewset_route_prefix ~= "" then
        -- Combine router inclusion path with ViewSet route prefix
        local full_path = "/" .. router_prefix:gsub("/$", "") .. "/" .. viewset_route_prefix
        full_path = full_path:gsub("//+", "/") -- Clean up double slashes
        table.insert(urls, full_path)
      end
    end
  end

  return urls
end

-- Infer HTTP method from function name
---@param function_name string
---@return string
function M.infer_http_method_from_name(function_name)
  local name_lower = function_name:lower()

  if name_lower:match "create" or name_lower:match "add" or name_lower:match "post" then
    return "POST"
  elseif name_lower:match "update" or name_lower:match "edit" or name_lower:match "put" then
    return "PUT"
  elseif name_lower:match "patch" or name_lower:match "partial" then
    return "PATCH"
  elseif name_lower:match "delete" or name_lower:match "remove" or name_lower:match "destroy" then
    return "DELETE"
  else
    return "GET" -- Default fallback
  end
end

-- Build fallback URL for functions without clear URL mapping
---@param function_name string
---@param file_path string
---@return string
function M.build_fallback_url(function_name, file_path)
  -- Extract app name from file path (e.g., users/views.py -> users)
  local app_name = file_path:match "([%w_]+)/views%.py$"
  if app_name then
    return "/" .. app_name .. "/" .. function_name
  end
  return "/api/" .. function_name
end

-- Find the parent class for a method at a given line number
---@param file_path string
---@param line_number number
---@return string?
function M.find_parent_class(file_path, line_number)
  if vim.fn.filereadable(file_path) == 1 then
    local content = vim.fn.readfile(file_path)
    
    -- Search backwards from the method line to find the class definition
    for i = line_number - 1, 1, -1 do
      local line = content[i]
      local class_name = line:match "^%s*class%s+([%w_]+)"  -- Allow indentation
      if class_name then
        return class_name
      end
    end
  end
  return nil
end

-- Convert ViewSet action names and Django method names to HTTP methods
---@param method_name string
---@return string
function M.convert_to_http_method(method_name)
  local method_lower = method_name:lower()
  
  if method_lower == "get" or method_lower == "list" or method_lower == "retrieve" then
    return "GET"
  elseif method_lower == "post" or method_lower == "create" then
    return "POST"
  elseif method_lower == "put" or method_lower == "update" then
    return "PUT"
  elseif method_lower == "patch" or method_lower == "partial_update" then
    return "PATCH"
  elseif method_lower == "delete" or method_lower == "destroy" then
    return "DELETE"
  else
    return method_name:upper() -- Fallback to uppercase
  end
end

-- Parse URL pattern from urls.py files
---@param content string
---@param search_method string
---@param file_path string
---@return string?, string?
function M.parse_url_pattern(content, search_method, file_path)
  -- Extract URL patterns: path('pattern', views.view_name)
  local url_path = content:match "path%s*%(%s*['\"]([^'\"]*)['\"]"
    or content:match "re_path%s*%(%s*r?['\"]([^'\"]+)['\"]"
    or content:match "url%s*%(%s*r?['\"]([^'\"]+)['\"]"
  
  if not url_path then
    return nil, nil
  end
  
  -- Extract view reference
  local view_ref = content:match "views%.([%w_]+)" or content:match "([%w_]+)%.as_view"
  if not view_ref then
    return nil, nil
  end
  
  -- Determine app prefix
  local app_name = file_path:match "([%w_]+)/urls%.py$"
  local app_prefix = ""
  if app_name then
    local main_urls_files = {
      "myproject/urls.py",
      "*/urls.py", 
      "urls.py"
    }
    
    for _, main_urls_pattern in ipairs(main_urls_files) do
      if main_urls_pattern:match "%*" then
        local possible_files = vim.fn.glob(main_urls_pattern, false, true)
        for _, main_urls_file in ipairs(possible_files) do
          local main_content = vim.fn.readfile(main_urls_file)
          app_prefix = M.extract_app_prefix(main_content, app_name)
          if app_prefix ~= "" then break end
        end
      else
        if vim.fn.filereadable(main_urls_pattern) == 1 then
          local main_content = vim.fn.readfile(main_urls_pattern)
          app_prefix = M.extract_app_prefix(main_content, app_name)
        end
      end
      if app_prefix ~= "" then break end
    end
  end
  
  -- Normalize and combine paths
  local normalized_path = M.normalize_django_path(url_path)
  local full_path = app_prefix .. normalized_path
  
  -- For URL patterns, we assume GET method unless we can determine otherwise
  -- This is a simplified approach - in reality we'd need to analyze the view
  local http_method = "GET"
  if search_method ~= "ALL" then
    http_method = search_method
  end
  
  return http_method, full_path
end

return M
