-- Rails framework implementation
local base = require "endpoint.framework.base"
local rails_config = require "endpoint.framework.config.rails"

-- Create a new Rails framework object inheriting from base
local M = base.new {}

function M:get_patterns(method)
  return rails_config.patterns[method:lower()] or {}
end

function M:get_file_types()
  -- Extract file extensions from file_patterns in config
  local file_extensions = {}
  for _, pattern in ipairs(rails_config.file_patterns) do
    local ext = pattern:match "%.(%w+)$"
    if ext then
      table.insert(file_extensions, ext)
    end
  end
  return file_extensions
end

function M:get_exclude_patterns()
  return rails_config.exclude_patterns
end

-- Extracts the endpoint path from Rails route definition or method definition
function M:extract_endpoint_path(content, method)
  -- First try to extract from route definitions like:
  -- get '/users', to: 'users#index'
  -- post '/users/:id', to: 'users#create'
  -- resources :users
  local path = content:match(method:lower() .. "%s+['\"]([^'\"]*)['\"]")
  if path then
    return path
  end

  -- Try to extract from resources definition
  local resource = content:match "resources%s+:(%w+)"
  if resource then
    -- For resources, return the resource name as path
    return "/" .. resource
  end

  -- Try to extract from resource definition (singular)
  resource = content:match "resource%s+:(%w+)"
  if resource then
    return "/" .. resource
  end

  -- For controller methods, try to infer from method name
  local method_name = content:match "def%s+(%w+)"
  if method_name then
    -- Standard Rails RESTful actions
    if method_name == "index" then
      return "" -- Will be combined with controller base path
    elseif method_name == "show" then
      return "/:id"
    elseif method_name == "create" then
      return ""
    elseif method_name == "update" then
      return "/:id"
    elseif method_name == "destroy" then
      return "/:id"
    else
      -- Custom action
      return "/" .. method_name
    end
  end

  return ""
end

-- Override path combiner for Rails specific behavior
function M:combine_paths(base, endpoint)
  -- If base is empty, just return endpoint (with leading slash if needed)
  if not base or base == "" then
    if not endpoint or endpoint == "" then
      return "/"
    end
    if endpoint:sub(1, 1) ~= "/" then
      return "/" .. endpoint
    end
    return endpoint
  end

  -- If endpoint is empty, just return base (with leading slash if needed)
  if not endpoint or endpoint == "" then
    if base:sub(1, 1) ~= "/" then
      return "/" .. base
    end
    return base
  end

  -- Both have content - combine them
  -- Remove trailing slash from base
  if base:sub(-1) == "/" then
    base = base:sub(1, -2)
  end

  -- Ensure base starts with slash
  if base:sub(1, 1) ~= "/" then
    base = "/" .. base
  end

  -- Add leading slash to endpoint if needed
  if endpoint:sub(1, 1) ~= "/" then
    endpoint = "/" .. endpoint
  end

  return base .. endpoint
end

-- Extracts base path from Rails controller class name
function M:get_base_path(file_path, line_number)
  -- Try vim.fn.readfile first, then fallback to io.lines if needed
  local lines = {}

  if vim and vim.fn and vim.fn.readfile then
    local ok, result = pcall(vim.fn.readfile, file_path)
    if ok and result and #result > 0 then
      lines = result
    else
      -- Fallback to io.lines even in vim environment if readfile fails
      local ok_io, err = pcall(function()
        local line_count = 0
        for line in io.lines(file_path) do
          line_count = line_count + 1
          lines[line_count] = line
        end
        if line_count == 0 then
          return ""
        end
      end)
      if not ok_io then
        -- File doesn't exist or can't be read
        return ""
      end
    end
  else
    -- Fallback to io.lines for testing environments
    local ok_io, err = pcall(function()
      local line_count = 0
      for line in io.lines(file_path) do
        line_count = line_count + 1
        lines[line_count] = line
      end
      if line_count == 0 then
        return ""
      end
    end)
    if not ok_io then
      -- File doesn't exist or can't be read
      return ""
    end
  end

  local controller_path = ""
  
  -- Look for class definition to extract controller name
  for i = 1, #lines do
    local line = lines[i] or ""
    local class_match = line:match "class%s+(%w+)Controller"
    if class_match then
      -- Convert CamelCase to snake_case and pluralize
      controller_path = class_match:gsub("(%u)", function(c)
        return "_" .. c:lower()
      end):gsub("^_", "")
      
      -- For Rails convention, controller names are usually plural
      -- but we'll use them as-is since they're already in the right format
      controller_path = "/" .. controller_path:gsub("_", "-"):lower()
      break
    end
  end

  -- If we're in a routes.rb file, look for namespace or scope
  if file_path:match "routes%.rb$" then
    for i = line_number, 1, -1 do
      local line = lines[i] or ""
      local namespace = line:match "namespace%s+[:\"]([^'\"]*)['\"]"
      if namespace then
        return "/" .. namespace
      end
      local scope = line:match "scope%s+['\"]([^'\"]*)['\"]"
      if scope then
        return scope
      end
    end
  end

  return controller_path
end

-- Override the default grep command builder for Rails
function M:get_grep_cmd(method, config)
  local patterns = self:get_patterns(method)
  if not patterns or #patterns == 0 then
    error("No patterns defined for method: " .. method)
  end

  local file_types = self:get_file_types()
  local exclude_patterns = self:get_exclude_patterns()

  local cmd = "rg"
  cmd = cmd .. " --line-number --column --no-heading --color=never"
  cmd = cmd .. " --case-sensitive"

  for _, file_type in ipairs(file_types) do
    cmd = cmd .. " --type " .. file_type
  end

  for _, pattern in ipairs(exclude_patterns) do
    cmd = cmd .. " --glob '!" .. pattern .. "'"
  end

  if config and config.rg_additional_args and config.rg_additional_args ~= "" then
    cmd = cmd .. " " .. config.rg_additional_args
  end

  -- For Rails, search for multiple patterns
  local pattern_group = "(" .. table.concat(patterns, "|") .. ")"
  cmd = cmd .. " '" .. pattern_group .. "'"

  return cmd
end

-- Parse ripgrep line and combine base path with endpoint path
function M:parse_line(line, method, config)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    return nil
  end

  line_number = tonumber(line_number) or 1
  column = tonumber(column) or 1

  local endpoint_path = self:extract_endpoint_path(content, method)
  local base_path = self:get_base_path(file_path, line_number)
  local full_path = self:combine_paths(base_path, endpoint_path)

  return {
    file_path = file_path,
    line_number = line_number,
    column = column,
    endpoint_path = full_path,
    method = method:upper(),
    raw_line = line,
    content = content,
  }
end

-- Rails specific method to handle route files
function M:parse_routes_file(file_path)
  local routes = {}
  local lines = {}
  
  if vim and vim.fn and vim.fn.readfile then
    local ok, result = pcall(vim.fn.readfile, file_path)
    if ok and result and #result > 0 then
      lines = result
    end
  else
    local ok_io = pcall(function()
      local line_count = 0
      for line in io.lines(file_path) do
        line_count = line_count + 1
        lines[line_count] = line
      end
    end)
    if not ok_io then
      return routes  -- Return empty routes if file can't be read
    end
  end

  for i, line in ipairs(lines) do
    -- Parse route definitions
    local method, path, controller_action = line:match "(%w+)%s+['\"]([^'\"]*)['\"],%s*to:%s*['\"]([^'\"]*)['\"]"
    if method and path and controller_action then
      table.insert(routes, {
        file_path = file_path,
        line_number = i,
        column = 1,
        endpoint_path = path,
        method = method:upper(),
        raw_line = line,
        content = line,
        controller_action = controller_action
      })
    end
    
    -- Parse resources
    local resource = line:match "resources%s+:(%w+)"
    if resource then
      local base_path = "/" .. resource
      -- Add standard RESTful routes
      local restful_routes = {
        {method = "GET", path = base_path, action = "index"},
        {method = "GET", path = base_path .. "/:id", action = "show"},
        {method = "POST", path = base_path, action = "create"},
        {method = "PUT", path = base_path .. "/:id", action = "update"},
        {method = "PATCH", path = base_path .. "/:id", action = "update"},
        {method = "DELETE", path = base_path .. "/:id", action = "destroy"}
      }
      
      for _, route in ipairs(restful_routes) do
        table.insert(routes, {
          file_path = file_path,
          line_number = i,
          column = 1,
          endpoint_path = route.path,
          method = route.method,
          raw_line = line,
          content = line,
          controller_action = resource .. "#" .. route.action
        })
      end
    end
  end
  
  return routes
end

return M