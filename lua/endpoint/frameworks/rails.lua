---@class endpoint.frameworks.rails
local M = {}

local fs = require "endpoint.utils.fs"

-- Detection
---@return boolean
function M.detect()
  return fs.has_file {
    "Gemfile",
    "config/routes.rb",
    "config/application.rb",
    "app/controllers",
  }
end

-- Search command generation
---@param method string
---@return string
function M.get_search_cmd(method)
  local controller_patterns = {
    GET = { "def index", "def show", "def new", "def edit" },
    POST = { "def create" },
    PUT = { "def update" }, -- Full replacement
    DELETE = { "def destroy" },
    PATCH = { "def update" }, -- Partial update (Rails default)
    ALL = {
      "def index",
      "def show",
      "def new",
      "def edit",
      "def create",
      "def update",
      "def destroy",
    },
  }

  -- Routes.rb patterns for different HTTP methods
  -- Skip resources/namespace declarations, focus on explicit routes and member/collection blocks
  local route_patterns = {
    GET = { "get ", "root " },
    POST = { "post " },
    PUT = { "put " },
    DELETE = { "delete " },
    PATCH = { "patch " },
    ALL = {
      "get ",
      "post ",
      "put ",
      "delete ",
      "patch ",
      "root ",
      "member do",
      "collection do",
    },
  }

  local method_patterns = controller_patterns[method:upper()] or controller_patterns.ALL
  local route_method_patterns = route_patterns[method:upper()] or route_patterns.ALL

  local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"
  cmd = cmd .. " --glob '**/*.rb'"
  cmd = cmd .. " --glob '!**/vendor/**'"
  cmd = cmd .. " --glob '!**/log/**'"
  cmd = cmd .. " --glob '!**/tmp/**'"

  -- Add controller patterns
  for _, pattern in ipairs(method_patterns) do
    cmd = cmd .. " -e '" .. pattern .. "'"
  end

  -- Add routes.rb patterns
  for _, pattern in ipairs(route_method_patterns) do
    cmd = cmd .. " -e '" .. pattern .. "'"
  end

  return cmd
end

-- Line parsing
---@param line string
---@param method string
---@return endpoint.entry|nil
function M.parse_line(line, method)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    return nil
  end

  -- Prioritize controller files over routes.rb
  local is_controller = file_path:match "controller"
  local is_routes = file_path:match "routes%.rb"

  if not (is_controller or is_routes) then
    return nil
  end

  line_number = tonumber(line_number)

  local endpoint_info = line_number and M.extract_endpoint_info(content, file_path, line_number)
  if not endpoint_info then
    return nil
  end

  -- Process both controller and routes files
  -- Routes.rb contains explicit endpoint definitions that should be included

  -- Filter by method if specified
  if method ~= "ALL" and endpoint_info.method ~= "ALL" and endpoint_info.method ~= method:upper() then
    return nil
  end

  return {
    file_path = file_path,
    line_number = tonumber(line_number),
    column = tonumber(column),
    method = endpoint_info.method,
    endpoint_path = endpoint_info.path,
    action = endpoint_info.action,
    display_value = M.format_display_value(endpoint_info, file_path),
  }
end

-- Extract endpoint information from Rails code
---@param content string
---@param file_path string
---@param line_number number
---@return table|nil
function M.extract_endpoint_info(content, file_path, line_number)
  -- Handle controller actions
  if file_path:match "controller" then
    return M.extract_controller_action(content, file_path, line_number)
  end

  -- Handle routes.rb definitions
  if file_path:match "routes%.rb" then
    return M.extract_route_definition(content, file_path, line_number)
  end

  return nil
end

-- Extract controller action information
---@param content string
---@param file_path string
---@param _ any
---@return table|nil
function M.extract_controller_action(content, file_path, _)
  local action = content:match "def ([%w_]+)"
  if not action then
    return nil
  end

  -- Map Rails controller actions to HTTP methods (following Rails 7+ conventions)
  local action_method_map = {
    index = "GET",
    show = "GET",
    new = "GET",
    edit = "GET",
    create = "POST",
    update = "PATCH", -- Rails uses PATCH by default for updates
    destroy = "DELETE",
  }

  -- For custom actions, try to infer from common patterns
  local method = action_method_map[action]
  if not method then
    -- Common patterns for custom actions
    if action:match "create" or action:match "add" or action:match "register" then
      method = "POST"
    elseif action:match "update" or action:match "edit" or action:match "modify" then
      method = "PATCH"
    elseif action:match "delete" or action:match "remove" or action:match "destroy" then
      method = "DELETE"
    else
      method = "GET" -- Default for custom actions like 'profile', 'search', etc.
    end
  end

  -- Generate path based on controller and action
  local controller_name = M.extract_controller_name(file_path)
  local path = controller_name and M.generate_action_path(controller_name, action, file_path)

  return {
    method = method,
    path = path,
    action = action,
    controller = controller_name, -- Add controller name
    file_path = file_path, -- Add file_path for display formatting
  }
end

-- Extract route definition from routes.rb
---@param content string
---@param file_path string
---@param line_number number
---@return table|nil
function M.extract_route_definition(content, file_path, line_number)
  -- Handle explicit route definitions like: get '/users', to: 'users#index'
  -- Match HTTP verbs followed by quoted paths (with single or double quotes)
  local route_method, route_path = content:match "(%w+)%s+['\"]([^'\"]+)['\"]"
  if route_method and route_path then
    -- Only accept valid HTTP verbs
    local valid_methods =
      { get = true, post = true, put = true, delete = true, patch = true, head = true, options = true }
    if valid_methods[route_method:lower()] then
      -- Try to extract controller#action from 'to:' parameter
      local controller_action = content:match "to:%s*['\"]([^'\"]+)['\"]"
      local controller, action = nil, nil

      if controller_action and controller_action:match "#" then
        controller, action = controller_action:match "([^#]+)#(%w+)"
      end

      return {
        method = route_method:upper(),
        path = route_path,
        controller = controller,
        action = action,
        controller_action = controller_action,
        file_path = file_path,
      }
    end
  end

  -- Handle root route: root 'controller#action' or root to: 'controller#action'
  if content:match "root%s+" then
    -- Try to extract controller#action pattern for root routes
    local controller_action = content:match "root%s+['\"]([^'\"]+)['\"]"
      or content:match "root%s+to:%s+['\"]([^'\"]+)['\"]"
    local action = "root" -- Default action name for root routes
    local controller = nil

    if controller_action and controller_action:match "#" then
      -- Extract controller and action from controller#action pattern
      controller, action = controller_action:match "([^#]+)#(%w+)"
      action = action or "root"
    end

    return {
      method = "GET",
      path = "/",
      action = action,
      controller = controller,
      controller_action = controller_action, -- Keep original for display
      file_path = file_path, -- Add file_path for controller name extraction
    }
  end

  -- Handle member/collection actions with context
  -- Only match HTTP verbs in member/collection blocks, not resources declarations
  local action_method, action_name = content:match "(get|post|put|delete|patch)%s+:(%w+)"
  if action_method and action_name then
    -- Need to determine the resource context from surrounding lines
    local resource_context = M.find_resource_context(file_path, line_number)
    if resource_context then
      local path
      if M.is_in_member_block(file_path, line_number) then
        path = resource_context.path .. "/:id/" .. action_name
      elseif M.is_in_collection_block(file_path, line_number) then
        path = resource_context.path .. "/" .. action_name
      else
        path = "/" .. action_name
      end

      return {
        method = action_method:upper(),
        path = path,
        action = action_name,
      }
    end
  end

  -- Skip resources/resource declarations - they generate endpoints but aren't endpoints themselves
  -- Focus on actual controller actions and explicit routes instead
  local resources_name = content:match "resources?%s+:(%w+)"
  if resources_name then
    return nil -- Skip resources/resource declarations
  end

  -- Skip namespace declarations - they don't represent actual endpoints
  -- Focus on controller actions and explicit routes instead
  local namespace_name = content:match "namespace%s+:(%w+)"
  if namespace_name then
    return nil -- Skip namespace declarations
  end

  return nil
end

-- Extract controller name from file path
---@param file_path string
---@return string|nil
function M.extract_controller_name(file_path)
  -- Handle standard controllers: app/controllers/users_controller.rb
  local controller = file_path:match "app/controllers/(.*)_controller%.rb$"
  if controller then
    return controller
  end

  -- Fallback for other patterns
  controller = file_path:match "app/controllers/(.*)%.rb$"
  if controller then
    controller = controller:gsub("_controller", "")
    return controller
  end

  return nil
end

-- Generate action path based on Rails conventions
---@param controller_name string
---@param action string
---@param file_path string
---@return string
function M.generate_action_path(controller_name, action, file_path)
  -- Handle API controllers: app/controllers/api/v1/users_controller.rb -> /api/v1/users
  if file_path:match "app/controllers/api/" then
    -- Use the full controller name as the path (it already contains the full namespace)
    local base_path = "/" .. controller_name

    -- Standard Rails action paths for API
    if action == "index" then
      return base_path
    elseif action == "show" then
      return base_path .. "/:id"
    elseif action == "new" then
      return base_path .. "/new"
    elseif action == "edit" then
      return base_path .. "/:id/edit"
    elseif action == "create" then
      return base_path
    elseif action == "update" then
      return base_path .. "/:id"
    elseif action == "destroy" then
      return base_path .. "/:id"
    else
      -- Custom actions
      return base_path .. M.get_action_suffix(action)
    end
  end

  -- Handle regular controllers
  -- For controllers like admin/users, keep the slash structure
  -- For controllers like oas_examples, keep the underscores as part of the resource name
  local base_path
  if controller_name:match "/" then
    -- Already has namespace structure (e.g., "admin/users")
    base_path = "/" .. controller_name
  else
    -- Single resource name (e.g., "oas_examples", "posts")
    base_path = "/" .. controller_name
  end

  -- Standard Rails action paths
  if action == "index" then
    return base_path
  elseif action == "show" then
    return base_path .. "/:id"
  elseif action == "new" then
    return base_path .. "/new"
  elseif action == "edit" then
    return base_path .. "/:id/edit"
  elseif action == "create" then
    return base_path
  elseif action == "update" then
    return base_path .. "/:id"
  elseif action == "destroy" then
    return base_path .. "/:id"
  else
    -- Custom actions - check if it's a member or collection action
    return base_path .. M.get_action_suffix(action)
  end
end

-- Get suffix for custom actions (member vs collection)
---@param action string
---@return string
function M.get_action_suffix(action)
  -- These are typically member actions (require ID)
  local member_actions = { "profile", "update_status", "like", "unlike", "share" }
  for _, member_action in ipairs(member_actions) do
    if action == member_action then
      return "/:id/" .. action
    end
  end

  -- Default to collection action (no ID required)
  return "/" .. action
end

-- Helper functions for context-aware route parsing

-- Find the resource context (parent resources block) for a given line
---@param file_path string
---@param line_number number
---@return table|nil
function M.find_resource_context(file_path, line_number)
  -- Check if file exists first
  if not fs.has_file(file_path) then
    return nil
  end

  local file_lines = vim.fn.readfile(file_path)
  if not file_lines or line_number > #file_lines then
    return nil
  end

  -- Look backwards to find the enclosing resources block
  for i = line_number - 1, 1, -1 do
    local line = file_lines[i]
    local resources_name = line:match "resources%s+:(%w+)"
    if resources_name then
      -- Check for namespace context
      local namespace = M.find_namespace_context(file_path, i)
      local path = namespace and ("/" .. namespace .. "/" .. resources_name) or ("/" .. resources_name)
      return {
        path = path,
        resource_name = resources_name,
        namespace = namespace,
      }
    end
  end

  return nil
end

-- Find namespace context for a given line
---@param file_path string
---@param line_number number
---@return string|nil
function M.find_namespace_context(file_path, line_number)
  local file_lines = vim.fn.readfile(file_path)
  if not file_lines or line_number > #file_lines then
    return nil
  end

  -- Look backwards to find namespace declarations
  local namespaces = {}
  for i = line_number - 1, 1, -1 do
    local line = file_lines[i]
    local namespace_name = line:match "namespace%s+:(%w+)"
    if namespace_name then
      table.insert(namespaces, 1, namespace_name) -- Insert at beginning to maintain order
    end
  end

  if #namespaces > 0 then
    return table.concat(namespaces, "/")
  end

  return nil
end

-- Check if a line is within a member block
---@param file_path string
---@param line_number number
---@return boolean
function M.is_in_member_block(file_path, line_number)
  local file_lines = vim.fn.readfile(file_path)
  if not file_lines or line_number > #file_lines then
    return false
  end

  -- Look backwards for "member do" and forwards for "end"
  local found_member = false
  for i = line_number - 1, 1, -1 do
    local line = file_lines[i]:match "%s*(.-)%s*$" -- Trim whitespace
    if line == "end" then
      break -- Hit an end before finding member do
    elseif line == "member do" then
      found_member = true
      break
    end
  end

  if not found_member then
    return false
  end

  -- Look forward to make sure we haven't passed the end
  for i = line_number, #file_lines do
    local line = file_lines[i]:match "%s*(.-)%s*$" -- Trim whitespace
    if line == "end" then
      return true -- We're within the member block
    end
  end

  return false
end

-- Check if a line is within a collection block
---@param file_path string
---@param line_number number
---@return boolean
function M.is_in_collection_block(file_path, line_number)
  local file_lines = vim.fn.readfile(file_path)
  if not file_lines or line_number > #file_lines then
    return false
  end

  -- Look backwards for "collection do" and forwards for "end"
  local found_collection = false
  for i = line_number - 1, 1, -1 do
    local line = file_lines[i]:match "%s*(.-)%s*$" -- Trim whitespace
    if line == "end" then
      break -- Hit an end before finding collection do
    elseif line == "collection do" then
      found_collection = true
      break
    end
  end

  if not found_collection then
    return false
  end

  -- Look forward to make sure we haven't passed the end
  for i = line_number, #file_lines do
    local line = file_lines[i]:match "%s*(.-)%s*$" -- Trim whitespace
    if line == "end" then
      return true -- We're within the collection block
    end
  end

  return false
end

-- Format display value with Rails action annotation
---@param endpoint_info table
---@param file_path string
---@return string
function M.format_display_value(endpoint_info, file_path)
  -- Get display format configuration
  local config = require "endpoint.config"
  local rails_config = config.get_value "frameworks" and config.get_value("frameworks").rails or {}
  local display_format = rails_config.display_format or "smart"
  local show_action_annotation = rails_config.show_action_annotation
  if show_action_annotation == nil then
    show_action_annotation = true -- Default to true
  end

  -- If action annotations are disabled, return simple format
  if not show_action_annotation then
    return endpoint_info.method .. " " .. endpoint_info.path
  end

  -- Add Rails action annotation for controller actions and special routes.rb entries
  if endpoint_info.action then
    if file_path:match "controller" then
      -- Controller actions: format based on configuration
      return M.format_controller_action(endpoint_info, display_format)
    elseif file_path:match "routes%.rb" and endpoint_info.action then
      -- Routes.rb entries: format based on configuration and route type
      return M.format_route_entry(endpoint_info, display_format)
    end
  end

  -- Default format without action
  return endpoint_info.method .. " " .. endpoint_info.path
end

-- Format controller action based on display format setting
---@param endpoint_info table
---@param display_format string
---@return string
function M.format_controller_action(endpoint_info, display_format)
  if display_format == "action_only" then
    return endpoint_info.method .. "[#" .. endpoint_info.action .. "] " .. endpoint_info.path
  elseif display_format == "controller_action" then
    -- Extract controller name from path if available
    local controller_name = endpoint_info.controller
    if not controller_name and endpoint_info.file_path then
      controller_name = M.extract_controller_name(endpoint_info.file_path)
    end
    if controller_name and controller_name ~= "unknown" then
      return endpoint_info.method .. "[" .. controller_name .. "#" .. endpoint_info.action .. "] " .. endpoint_info.path
    else
      return endpoint_info.method .. "[#" .. endpoint_info.action .. "] " .. endpoint_info.path
    end
  elseif display_format == "smart" then
    -- Smart format: use controller#action for clarity
    local controller_name = endpoint_info.controller
    if not controller_name and endpoint_info.file_path then
      controller_name = M.extract_controller_name(endpoint_info.file_path)
    end
    if controller_name and controller_name ~= "unknown" then
      return endpoint_info.method .. "[" .. controller_name .. "#" .. endpoint_info.action .. "] " .. endpoint_info.path
    else
      return endpoint_info.method .. "[#" .. endpoint_info.action .. "] " .. endpoint_info.path
    end
  end

  -- Default fallback
  return endpoint_info.method .. "[#" .. endpoint_info.action .. "] " .. endpoint_info.path
end

-- Format routes.rb entry based on display format setting
---@param endpoint_info table
---@param display_format string
---@return string
function M.format_route_entry(endpoint_info, display_format)
  local is_root_route = endpoint_info.action == "root" or endpoint_info.path == "/"

  if display_format == "action_only" then
    return endpoint_info.method .. "[#" .. endpoint_info.action .. "] " .. endpoint_info.path
  elseif display_format == "controller_action" then
    -- For root routes, try to show actual controller#action if available
    if is_root_route and endpoint_info.controller_action then
      return endpoint_info.method .. "[" .. endpoint_info.controller_action .. "] " .. endpoint_info.path
    else
      local controller_name = endpoint_info.controller
      if controller_name then
        return endpoint_info.method
          .. "["
          .. controller_name
          .. "#"
          .. endpoint_info.action
          .. "] "
          .. endpoint_info.path
      else
        return endpoint_info.method .. "[#" .. endpoint_info.action .. "] " .. endpoint_info.path
      end
    end
  elseif display_format == "smart" then
    -- Smart format for routes.rb entries
    if is_root_route then
      -- For root routes, show controller#action directly without "root→" prefix
      if endpoint_info.controller_action then
        return endpoint_info.method .. "[" .. endpoint_info.controller_action .. "] " .. endpoint_info.path
      else
        return endpoint_info.method .. "[root] " .. endpoint_info.path
      end
    else
      -- Regular routes: show full controller#action if available
      if endpoint_info.controller_action then
        return endpoint_info.method .. "[" .. endpoint_info.controller_action .. "] " .. endpoint_info.path
      else
        return endpoint_info.method .. "[#" .. endpoint_info.action .. "] " .. endpoint_info.path
      end
    end
  end

  -- Default fallback
  return endpoint_info.method .. "[#" .. endpoint_info.action .. "] " .. endpoint_info.path
end

return M
