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

-- Search command generation (optimized for caching strategy)
---@param method string
---@return string
function M.get_search_cmd(method)
  -- For ALL method, we discover all endpoints via comprehensive analysis
  -- For specific methods, we use cached results and filter
  if method == "ALL" then
    return "rg --type py --line-number --column 'path\\s*\\(|re_path\\s*\\(|url\\s*\\(|router\\.register' --glob '!**/migrations/**' --glob '!**/__pycache__/**'"
  else
    -- Return empty command for specific methods - they will use cached results
    return "echo '# Using cached Django endpoints'"
  end
end

-- Main endpoint discovery function
---@return table
function M.discover_all_endpoints()
  local endpoints = {}
  local root_urlconf = M.find_root_urlconf()

  if root_urlconf then
    M.parse_urlconf_recursive(root_urlconf, "", endpoints)
  end

  return endpoints
end

-- Find root URLconf (settings.ROOT_URLCONF or main urls.py)
---@return string?
function M.find_root_urlconf()
  -- First try to find ROOT_URLCONF from settings
  local settings_files = vim.fn.glob("**/settings.py", false, true)

  for _, settings_file in ipairs(settings_files) do
    if vim.fn.filereadable(settings_file) == 1 then
      local content = table.concat(vim.fn.readfile(settings_file), "\n")
      local root_urlconf = content:match "ROOT_URLCONF%s*=%s*['\"]([^'\"]+)['\"]"
      if root_urlconf then
        local urlconf_path = root_urlconf:gsub("%.", "/") .. ".py"

        -- Try different path variations
        local path_candidates = {
          urlconf_path,
          "./" .. urlconf_path,
          vim.fn.getcwd() .. "/" .. urlconf_path,
        }

        for _, candidate in ipairs(path_candidates) do
          if vim.fn.filereadable(candidate) == 1 then
            return candidate
          end
        end
      end
    end
  end

  -- Fallback: find main urls.py (contains admin.site.urls)
  local url_files = vim.fn.glob("**/urls.py", false, true)

  for _, file in ipairs(url_files) do
    if vim.fn.filereadable(file) == 1 then
      local content = table.concat(vim.fn.readfile(file), "\n")
      if content:match "admin%.site%.urls" then
        return file
      end
    end
  end

  return nil
end

-- Parse URLconf file recursively
---@param file_path string
---@param base_path string
---@param endpoints table
function M.parse_urlconf_recursive(file_path, base_path, endpoints)
  if vim.fn.filereadable(file_path) ~= 1 then
    return
  end

  local content = vim.fn.readfile(file_path)

  for i, line in ipairs(content) do
    local trimmed = line:gsub("^%s*", ""):gsub("%s*$", "")

    -- Skip comments and empty lines
    if trimmed == "" or trimmed:match "^#" then
      goto continue
    end

    -- Parse URL patterns
    local pattern_info = M.parse_url_pattern(line)
    if pattern_info then
      local full_path = M.combine_paths(base_path, pattern_info.path)

      if pattern_info.type == "include" then
        -- Recursively parse included URLconf
        local included_file = M.resolve_include_path(pattern_info.target, file_path)
        if included_file then
          M.parse_urlconf_recursive(included_file, full_path, endpoints)
        end
      elseif pattern_info.type == "router" then
        -- Handle DRF router registration
        local router_endpoints = M.generate_router_endpoints(pattern_info, full_path, file_path)
        for _, endpoint in ipairs(router_endpoints) do
          table.insert(endpoints, endpoint)
        end
      else
        -- Handle regular view
        local view_endpoints = M.generate_view_endpoints(pattern_info, full_path, file_path, i)
        for _, endpoint in ipairs(view_endpoints) do
          table.insert(endpoints, endpoint)
        end
      end
    end

    ::continue::
  end
end

-- Parse individual URL pattern line
---@param line string
---@return table?
function M.parse_url_pattern(line)
  -- Match different URL pattern types
  local path_pattern = line:match "path%s*%(%s*['\"]([^'\"]*)['\"]"
  local re_path_pattern = line:match "re_path%s*%(%s*r?['\"]([^'\"]+)['\"]"
  local url_pattern = line:match "url%s*%(%s*r?['\"]([^'\"]+)['\"]"

  local pattern = path_pattern or re_path_pattern or url_pattern
  if not pattern then
    -- Check for router registration
    local base_path, viewset_class = line:match "router%.register%s*%(%s*r?['\"]([^'\"]+)['\"]%s*,%s*([%w_.]+)"
    if base_path and viewset_class then
      return {
        type = "router",
        path = base_path,
        target = viewset_class,
      }
    end
    return nil
  end

  -- Determine pattern type and target
  if line:match "include%s*%(" or line:match "%.urls" then
    local include_target = line:match "include%s*%(%s*['\"]([^'\"]+)['\"]"
      or line:match "include%s*%(%s*([%w_.]+)%.urls"
      or line:match "([%w_.]+%.urls)" -- admin.site.urls

    return {
      type = "include",
      path = pattern,
      target = include_target,
    }
  else
    -- Regular view pattern (order matters!)
    local string_match = line:match "['\"]([%w_%.]+%.views%.[%w_]+)['\"]" -- 'users.views.user_detail' (full string) - more specific!
    local class_match = line:match "([%w_%.]+)%.as_view%s*%(%)" -- Class.as_view()
    local views_match = line:match "views%.([%w_]+)" -- views.function_name
    local comma_match = line:match "([%w_%.]+)%s*," -- view_function,

    local view_target = string_match or class_match or views_match or comma_match

    -- Mark CBV by adding .as_view back if it was a class match
    if class_match and line:match "%.as_view%s*%(%)" then
      view_target = class_match .. ".as_view"
    end

    if view_target then
      return {
        type = "view",
        path = pattern,
        target = view_target,
        is_regex = re_path_pattern or url_pattern,
      }
    end
  end

  return nil
end

-- Resolve include path to actual file
---@param include_target string
---@param current_file string
---@return string?
function M.resolve_include_path(include_target, current_file)
  if not include_target then
    return nil
  end

  -- Handle different include formats
  local app_path = include_target:gsub("%.urls$", "")
  local candidates = {
    app_path .. "/urls.py",
    app_path:gsub("%.", "/") .. "/urls.py",
  }

  -- Try relative to current file
  local current_dir = vim.fn.fnamemodify(current_file, ":h")
  for _, candidate in ipairs(candidates) do
    local full_path = current_dir .. "/" .. candidate
    if vim.fn.filereadable(full_path) == 1 then
      return full_path
    end
  end

  -- Try from project root
  for _, candidate in ipairs(candidates) do
    if vim.fn.filereadable(candidate) == 1 then
      return candidate
    end
  end

  return nil
end

-- Generate endpoints for DRF ViewSet
---@param pattern_info table
---@param base_path string
---@param file_path string
---@return table
function M.generate_router_endpoints(pattern_info, base_path, file_path)
  local endpoints = {}
  local viewset_class = pattern_info.target

  -- Find ViewSet class definition and analyze its methods
  local viewset_info = M.analyze_viewset_class(viewset_class, file_path)

  -- Standard ViewSet actions
  local standard_actions = {
    { action = "list", methods = { "GET" }, path_suffix = "" },
    { action = "create", methods = { "POST" }, path_suffix = "" },
    { action = "retrieve", methods = { "GET" }, path_suffix = "/<int:pk>" },
    { action = "update", methods = { "PUT" }, path_suffix = "/<int:pk>" },
    { action = "partial_update", methods = { "PATCH" }, path_suffix = "/<int:pk>" },
    { action = "destroy", methods = { "DELETE" }, path_suffix = "/<int:pk>" },
  }

  -- Generate standard action endpoints if methods exist in ViewSet
  for _, action_config in ipairs(standard_actions) do
    local action_line = M.find_viewset_action_line(viewset_info, action_config.action)
    if action_line then
      for _, method in ipairs(action_config.methods) do
        local endpoint_path =
          M.normalize_endpoint_path(base_path .. "/" .. pattern_info.path .. action_config.path_suffix)
        table.insert(endpoints, {
          method = method,
          endpoint_path = endpoint_path,
          file_path = viewset_info.file_path or file_path,
          line_number = action_line,
          column = 1,
          display_value = method .. " " .. endpoint_path,
        })
      end
    end
  end

  -- Generate custom action endpoints
  for _, custom_action in ipairs(viewset_info.custom_actions or {}) do
    local path_suffix = custom_action.detail and ("/<int:pk>/" .. custom_action.name) or ("/" .. custom_action.name)
    local endpoint_path = M.normalize_endpoint_path(base_path .. "/" .. pattern_info.path .. path_suffix)

    for _, method in ipairs(custom_action.methods) do
      table.insert(endpoints, {
        method = method,
        endpoint_path = endpoint_path,
        file_path = viewset_info.file_path or file_path,
        line_number = custom_action.line_number,
        column = 1,
        display_value = method .. " " .. endpoint_path,
      })
    end
  end

  return endpoints
end

-- Generate endpoints for regular view
---@param pattern_info table
---@param full_path string
---@param file_path string
---@param line_number number
---@return table
function M.generate_view_endpoints(pattern_info, full_path, file_path, line_number)
  local endpoints = {}
  local view_target = pattern_info.target

  -- Analyze view to determine HTTP methods
  local view_info = M.analyze_view_target(view_target, file_path)
  local endpoint_path = M.normalize_endpoint_path(full_path)

  for _, method in ipairs(view_info.methods) do
    -- For each method, get method-specific view info
    local method_specific_info = view_info
    if view_target:match "%.as_view$" then
      -- Re-analyze CBV with specific method to get correct line number
      method_specific_info = M.analyze_view_target(view_target, file_path, method)
    elseif #view_info.methods > 1 then
      -- Re-analyze function-based view for method-specific line if multiple methods
      method_specific_info = M.analyze_view_target(view_target, file_path, method)
    end

    table.insert(endpoints, {
      method = method,
      endpoint_path = endpoint_path,
      file_path = method_specific_info.file_path or file_path,
      line_number = method_specific_info.line_number or line_number,
      column = 1,
      display_value = method .. " " .. endpoint_path,
      -- Store original URL info for ripgrep matching
      url_file_path = file_path,
      url_line_number = line_number,
    })
  end

  return endpoints
end

-- Analyze ViewSet class
---@param viewset_class string
---@param context_file string
---@return table
function M.analyze_viewset_class(viewset_class, context_file)
  local viewset_info = {
    name = viewset_class,
    actions = {},
    custom_actions = {},
    file_path = nil,
  }

  -- Search for ViewSet file
  local viewset_files = { context_file }
  -- Also check common ViewSet locations
  local dir = vim.fn.fnamemodify(context_file, ":h")
  table.insert(viewset_files, dir .. "/viewsets.py")
  table.insert(viewset_files, dir .. "/views.py")

  for _, file_path in ipairs(viewset_files) do
    if vim.fn.filereadable(file_path) == 1 then
      local content = vim.fn.readfile(file_path)
      local in_viewset = false
      local class_indent = 0

      for i, line in ipairs(content) do
        -- Check for ViewSet class definition
        if line:match("class%s+" .. viewset_class .. "%s*%(.*ViewSet") then
          in_viewset = true
          class_indent = #line:match "^%s*"
          viewset_info.file_path = file_path
        elseif in_viewset then
          local current_indent = #line:match "^%s*"

          -- Exit class if we've dedented beyond class level
          if current_indent <= class_indent and line:match "^%s*class" then
            break
          end

          -- Look for ViewSet methods
          local method_match = line:match "^%s+def%s+(list|create|retrieve|update|partial_update|destroy)%s*%("
          if method_match then
            table.insert(viewset_info.actions, {
              name = method_match,
              line_number = i,
            })
          end

          -- Look for custom actions
          local action_decorator = line:match "^%s*@action"
          if action_decorator then
            local detail = line:match "detail%s*=%s*([%w_]+)" == "True"
            local methods_str = line:match "methods%s*=%s*%[([^%]]+)%]"
            local methods = { "GET" } -- default

            if methods_str then
              methods = {}
              for method in methods_str:gmatch "['\"]([^'\"]+)['\"]" do
                table.insert(methods, method:upper())
              end
            end

            -- Find function name on next lines
            for j = i + 1, math.min(i + 3, #content) do
              local func_line = content[j]
              local func_name = func_line:match "^%s*def%s+([%w_]+)%s*%("
              if func_name then
                table.insert(viewset_info.custom_actions, {
                  name = func_name,
                  detail = detail,
                  methods = methods,
                  line_number = j,
                })
                break
              end
            end
          end
        end
      end

      if in_viewset then
        break -- Found the ViewSet, no need to check other files
      end
    end
  end

  return viewset_info
end

-- Find ViewSet action line number
---@param viewset_info table
---@param action_name string
---@return number?
function M.find_viewset_action_line(viewset_info, action_name)
  for _, action in ipairs(viewset_info.actions) do
    if action.name == action_name then
      return action.line_number
    end
  end
  -- Return nil if action not found (will use default implementation)
  return nil
end

-- Analyze view target to determine HTTP methods and location
---@param view_target string
---@param context_file string
---@param target_method string? Optional HTTP method for CBV method-specific line
---@return table
function M.analyze_view_target(view_target, context_file, target_method)
  local view_info = {
    methods = { "GET" }, -- default
    file_path = nil,
    line_number = nil,
  }

  -- Check if it's a views.method reference
  if view_target:match "^[%w_]+$" then
    -- First, try to find the function in imports from the context file
    local import_info = M.find_imported_function(view_target, context_file)
    if import_info then
      view_info.file_path = import_info.file_path
      local function_info = M.analyze_function_view(view_target, import_info.file_path, target_method)
      view_info.methods = function_info.methods
      view_info.line_number = function_info.line_number
    else
      -- Fallback: Function-based view in same app
      local views_file = vim.fn.fnamemodify(context_file, ":h") .. "/views.py"
      if vim.fn.filereadable(views_file) == 1 then
        view_info.file_path = views_file
        local function_info = M.analyze_function_view(view_target, views_file, target_method)
        view_info.methods = function_info.methods
        view_info.line_number = function_info.line_number
      end
    end
  elseif view_target:match "%.views%." or view_target:match "^[%w_]+%.views%.[%w_]+$" then
    -- String reference like 'users.views.user_detail'
    local app_name, func_name = view_target:match "([%w_]+)%.views%.([%w_]+)"
    if app_name and func_name then
      -- Try to find the views file
      local views_file_candidates = {
        app_name .. "/views.py",
        "./" .. app_name .. "/views.py",
        vim.fn.getcwd() .. "/" .. app_name .. "/views.py",
      }

      for _, candidate in ipairs(views_file_candidates) do
        if vim.fn.filereadable(candidate) == 1 then
          view_info.file_path = candidate
          local function_info = M.analyze_function_view(func_name, candidate, target_method)
          view_info.methods = function_info.methods
          view_info.line_number = function_info.line_number
          break
        end
      end
    end
  elseif view_target:match "%.as_view$" then
    -- Class-based view
    local full_class_name = view_target:gsub("%.as_view$", "")
    local class_name = full_class_name:match "views%.([%w_]+)$" or full_class_name:match "([%w_]+)$" or full_class_name

    local class_info = M.analyze_class_view(class_name, context_file, target_method)
    view_info.methods = class_info.methods
    view_info.line_number = class_info.line_number
    view_info.file_path = class_info.file_path
  end

  return view_info
end

-- Analyze function-based view
---@param func_name string
---@param views_file string
---@param target_method string? Optional HTTP method to find specific line
---@return table
function M.analyze_function_view(func_name, views_file, target_method)
  local result = {
    methods = { "GET" },
    line_number = nil,
  }

  if vim.fn.filereadable(views_file) == 1 then
    local content = vim.fn.readfile(views_file)
    local in_function = false

    for i, line in ipairs(content) do
      -- Check for function definition
      if line:match("^def%s+" .. func_name .. "%s*%(") then
        in_function = true
        result.line_number = i
        result.methods = {}

        -- Check for decorators above the function
        for j = math.max(1, i - 5), i - 1 do
          local decorator_line = content[j]
          local api_view_methods = decorator_line:match "@api_view%s*\\(%s*%[([^%]]+)%]"
          if api_view_methods then
            for method in api_view_methods:gmatch "['\"]([^'\"]+)['\"]" do
              table.insert(result.methods, method:upper())
            end
            return result
          end
        end
      elseif in_function and line:match "^def%s+" then
        break
      elseif in_function then
        -- Analyze function body for method checks
        if line:match "request%.method%s*==%s*['\"]GET['\"]" then
          table.insert(result.methods, "GET")
          -- If looking for specific method, update line number
          if target_method and target_method:upper() == "GET" then
            result.line_number = i
          end
        elseif line:match "request%.method%s*==%s*['\"]POST['\"]" then
          table.insert(result.methods, "POST")
          if target_method and target_method:upper() == "POST" then
            result.line_number = i
          end
        elseif line:match "request%.method%s*==%s*['\"]PUT['\"]" then
          table.insert(result.methods, "PUT")
          if target_method and target_method:upper() == "PUT" then
            result.line_number = i
          end
        elseif line:match "request%.method%s*==%s*['\"]PATCH['\"]" then
          table.insert(result.methods, "PATCH")
          if target_method and target_method:upper() == "PATCH" then
            result.line_number = i
          end
        elseif line:match "request%.method%s*==%s*['\"]DELETE['\"]" then
          table.insert(result.methods, "DELETE")
          if target_method and target_method:upper() == "DELETE" then
            result.line_number = i
          end
        end
      end
    end
  end

  -- Default to GET if no specific methods found
  if #result.methods == 0 then
    result.methods = { "GET" }
  end

  return result
end

-- Analyze class-based view
---@param class_name string
---@param context_file string
---@param target_method string? Optional HTTP method to find specific line
---@return table
function M.analyze_class_view(class_name, context_file, target_method)
  local result = {
    methods = {},
    line_number = nil,
    file_path = nil,
  }

  -- Try to find the class definition
  local views_file = vim.fn.fnamemodify(context_file, ":h") .. "/views.py"

  if vim.fn.filereadable(views_file) == 1 then
    result.file_path = views_file
    local content = vim.fn.readfile(views_file)
    local in_class = false
    local class_indent = 0

    for i, line in ipairs(content) do
      -- Check for class definition
      if line:match("^class%s+" .. class_name .. "%s*%(") then
        in_class = true
        class_indent = #line:match "^%s*"
        result.line_number = i
      elseif in_class then
        local current_indent = #line:match "^%s*"

        -- Exit class if dedented beyond class level
        if current_indent <= class_indent and line:match "^%s*class" then
          break
        end

        -- Look for HTTP method handlers
        if line:match "^%s+def%s+get%s*%(" then
          table.insert(result.methods, "GET")
          -- If looking for specific method, update line number
          if target_method and target_method:upper() == "GET" then
            result.line_number = i
          end
        elseif line:match "^%s+def%s+post%s*%(" then
          table.insert(result.methods, "POST")
          if target_method and target_method:upper() == "POST" then
            result.line_number = i
          end
        elseif line:match "^%s+def%s+put%s*%(" then
          table.insert(result.methods, "PUT")
          if target_method and target_method:upper() == "PUT" then
            result.line_number = i
          end
        elseif line:match "^%s+def%s+patch%s*%(" then
          table.insert(result.methods, "PATCH")
          if target_method and target_method:upper() == "PATCH" then
            result.line_number = i
          end
        elseif line:match "^%s+def%s+delete%s*%(" then
          table.insert(result.methods, "DELETE")
          if target_method and target_method:upper() == "DELETE" then
            result.line_number = i
          end
        end
      end
    end
  end

  -- Infer methods from class name if none found
  if #result.methods == 0 then
    if class_name:match "List" then
      result.methods = { "GET", "POST" }
    elseif class_name:match "Detail" then
      result.methods = { "GET", "PUT", "PATCH", "DELETE" }
    elseif class_name:match "Create" then
      result.methods = { "GET", "POST" }
    elseif class_name:match "Update" then
      result.methods = { "GET", "PUT", "PATCH" }
    elseif class_name:match "Delete" then
      result.methods = { "GET", "DELETE" }
    else
      result.methods = { "GET" }
    end
  end

  return result
end

-- Find imported function in URLconf file
---@param func_name string
---@param urlconf_file string
---@return table?
function M.find_imported_function(func_name, urlconf_file)
  if vim.fn.filereadable(urlconf_file) ~= 1 then
    return nil
  end

  local content = vim.fn.readfile(urlconf_file)

  for _, line in ipairs(content) do
    -- Look for import statements that import the function
    -- from api.views import health_check
    local module_path = line:match("from%s+([%w_.]+)%s+import%s+.*" .. func_name)
    if module_path then
      -- Convert module path to file path
      local file_path = module_path:gsub("%.", "/") .. ".py"

      -- Try different path variations
      local path_candidates = {
        file_path,
        "./" .. file_path,
        vim.fn.getcwd() .. "/" .. file_path,
      }

      for _, candidate in ipairs(path_candidates) do
        if vim.fn.filereadable(candidate) == 1 then
          return {
            file_path = candidate,
            module = module_path,
          }
        end
      end
    end

    -- Also check for: from api.views import health_check, other_func
    local multi_import_line = line:match "from%s+([%w_.]+)%s+import%s+(.+)"
    if multi_import_line then
      local import_module_path, imports = multi_import_line:match "([%w_.]+)%s+import%s+(.+)"
      if import_module_path and imports then
        -- Check if our function is in the import list
        for import_func in imports:gmatch "([%w_]+)" do
          if import_func == func_name then
            local import_file_path = import_module_path:gsub("%.", "/") .. ".py"

            local path_candidates = {
              import_file_path,
              "./" .. import_file_path,
              vim.fn.getcwd() .. "/" .. import_file_path,
            }

            for _, candidate in ipairs(path_candidates) do
              if vim.fn.filereadable(candidate) == 1 then
                return {
                  file_path = candidate,
                  module = import_module_path,
                }
              end
            end
          end
        end
      end
    end
  end

  return nil
end

-- Combine URL paths
---@param prefix string
---@param suffix string
---@return string
function M.combine_paths(prefix, suffix)
  if not prefix or prefix == "" then
    return suffix or ""
  end

  if not suffix or suffix == "" then
    return prefix
  end

  -- Normalize paths
  prefix = prefix:gsub("/$", "")
  if not suffix:match "^/" then
    suffix = "/" .. suffix
  end

  return prefix .. suffix
end

-- Normalize endpoint path for display
---@param path string
---@return string
function M.normalize_endpoint_path(path)
  if not path or path == "" then
    return "/"
  end

  -- Convert Django path parameters using template format
  local config = require("endpoint.config").get()
  local django_config = config.frameworks and config.frameworks.django or {}
  local content_format = django_config.url_param_format or "%v:%t"
  local fallback_content = django_config.url_param_fallback or "%v"
  local brackets = django_config.url_param_brackets or "{}"

  -- Parse bracket style
  local open_bracket, close_bracket
  if brackets == "{}" then
    open_bracket, close_bracket = "{", "}"
  elseif brackets == "<>" then
    open_bracket, close_bracket = "<", ">"
  elseif brackets == "[]" then
    open_bracket, close_bracket = "[", "]"
  elseif brackets == "()" then
    open_bracket, close_bracket = "(", ")"
  else
    -- Custom bracket pair: assume first half is open, second half is close
    local mid = math.floor(#brackets / 2)
    if mid > 0 then
      open_bracket = brackets:sub(1, mid)
      close_bracket = brackets:sub(mid + 1)
    else
      open_bracket, close_bracket = "{", "}"
    end
  end

  local function format_param(content)
    return open_bracket .. content .. close_bracket
  end

  path = path:gsub("<([^:>]+):([^>]+)>", function(param_type, param_name)
    local param_content = content_format

    -- Apply replacements
    param_content = param_content:gsub("%%v", param_name)
    param_content = param_content:gsub("%%t", param_type)

    -- If format still contains unreplaced placeholders, use fallback
    if param_content:match "%%[vt]" then
      param_content = fallback_content:gsub("%%v", param_name)
    end

    return format_param(param_content)
  end)

  -- Convert regex named groups (?P<name>pattern) using fallback format
  path = path:gsub("%(%?P<([^>]+)>[^)]*%)", function(param_name)
    local regex_content = fallback_content:gsub("%%v", param_name)
    return format_param(regex_content)
  end)

  -- Remove regex anchors and escape sequences
  path = path:gsub("^%^", ""):gsub("%$$", "")
  path = path:gsub("\\", "")

  -- Ensure path starts with /
  if not path:match "^/" then
    path = "/" .. path
  end

  -- Clean up multiple slashes
  path = path:gsub("//+", "/")

  -- Remove trailing slash unless it's root
  if path ~= "/" then
    path = path:gsub("/$", "")
  end

  return path
end

-- Global cache for discovered endpoints
local all_endpoints_cache = {
  endpoints = nil,
  last_scan = 0,
  version = 2, -- Increment to invalidate old cache
}

-- Parse ripgrep output line (main entry point)
---@param line string
---@param method string
---@return endpoint.entry?
function M.parse_line(line, method)
  -- Parse line components first
  local file_path, line_number = line:match "([^:]+):(%d+):"
  if not file_path then
    return nil
  end

  -- For specific methods, use cached results if available
  if method ~= "ALL" and all_endpoints_cache.endpoints then
    local current_time = os.time()
    if (current_time - all_endpoints_cache.last_scan) < 30 then
      -- Use URL info for matching cached results
      local match_file = file_path
      local match_line = tonumber(line_number)

      for _, endpoint in ipairs(all_endpoints_cache.endpoints) do
        local cached_match_file = endpoint.url_file_path or endpoint.file_path
        local cached_match_line = endpoint.url_line_number or endpoint.line_number

        if cached_match_file == match_file and cached_match_line == match_line and endpoint.method == method then
          return {
            method = endpoint.method,
            endpoint_path = endpoint.endpoint_path,
            file_path = endpoint.file_path,
            line_number = endpoint.line_number,
            column = endpoint.column,
            display_value = endpoint.display_value,
          }
        end
      end
    end
  end

  -- Get all discovered endpoints
  local all_endpoints = M.discover_all_endpoints()
  if method == "ALL" then
    -- Cache them for ALL method
    all_endpoints_cache.endpoints = all_endpoints
    all_endpoints_cache.last_scan = os.time()
  end

  -- Find matching endpoint by file, line, and method
  for _, endpoint in ipairs(all_endpoints) do
    -- Use url_file_path and url_line_number for matching if available (CBV case)
    local match_file = endpoint.url_file_path or endpoint.file_path
    local match_line = endpoint.url_line_number or endpoint.line_number

    if
      match_file == file_path
      and match_line == tonumber(line_number)
      and (method == "ALL" or endpoint.method == method)
    then
      return {
        method = endpoint.method,
        endpoint_path = endpoint.endpoint_path,
        file_path = endpoint.file_path,
        line_number = endpoint.line_number,
        column = endpoint.column,
        display_value = endpoint.display_value,
      }
    end
  end

  return nil
end

-- Get all endpoints for a specific method (used by caching system)
---@param method string
---@return endpoint.entry[]
function M.get_all_endpoints_for_method(method)
  -- Ensure we have discovered all endpoints
  if not all_endpoints_cache.endpoints or (os.time() - all_endpoints_cache.last_scan) > 30 then
    all_endpoints_cache.endpoints = M.discover_all_endpoints()
    all_endpoints_cache.last_scan = os.time()
  end

  if method == "ALL" then
    return all_endpoints_cache.endpoints
  end

  -- Filter by specific method
  local filtered = {}
  for _, endpoint in ipairs(all_endpoints_cache.endpoints) do
    if endpoint.method == method then
      table.insert(filtered, endpoint)
    end
  end

  return filtered
end

return M