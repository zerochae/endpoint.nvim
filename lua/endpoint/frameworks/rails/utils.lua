-- Rails Framework Utility Functions
---@class endpoint.frameworks.rails.utils
local M = {}

local fs = require "endpoint.utils.fs"

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

-- Determine HTTP method from Rails controller action
---@param action string
---@return string
function M.determine_http_method(action)
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

  return method
end

-- Extract route definition from routes.rb content
---@param content string
---@param line_number number
---@return table|nil
function M.extract_route_definition(content, line_number)
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
        line_number = line_number,
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
      line_number = line_number,
    }
  end

  -- Handle member/collection actions with context
  -- Only match HTTP verbs in member/collection blocks, not resources declarations
  local action_method, action_name = content:match "(get|post|put|delete|patch)%s+:(%w+)"
  if action_method and action_name then
    return {
      method = action_method:upper(),
      action = action_name,
      line_number = line_number,
      needs_context = true, -- Indicates this needs resource context lookup
    }
  end

  -- Skip resources/resource declarations
  if content:match "resources?%s+:" then
    return nil
  end

  -- Skip namespace declarations
  if content:match "namespace%s+:" then
    return nil
  end

  return nil
end

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

return M