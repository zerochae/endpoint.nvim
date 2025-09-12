---@class endpoint.RailsFramework
local M = {}

-- Detection
function M.detect()
  return vim.fn.filereadable "Gemfile" == 1
    or vim.fn.filereadable "config/routes.rb" == 1
    or vim.fn.filereadable "config/application.rb" == 1
    or vim.fn.isdirectory "app/controllers" == 1
end

-- Search command generation
function M.get_search_cmd(method)
  local patterns = {
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

  local method_patterns = patterns[method:upper()] or patterns.ALL

  local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"
  cmd = cmd .. " --glob '**/*.rb'"
  cmd = cmd .. " --glob '!**/vendor/**'"
  cmd = cmd .. " --glob '!**/log/**'"
  cmd = cmd .. " --glob '!**/tmp/**'"

  -- Add patterns
  for _, pattern in ipairs(method_patterns) do
    cmd = cmd .. " -e '" .. pattern .. "'"
  end

  return cmd
end

-- Line parsing
function M.parse_line(line, method)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    return nil
  end

  -- Prioritize controller files over routes.rb
  local is_controller = file_path:match("controller")
  local is_routes = file_path:match("routes%.rb")
  
  if not (is_controller or is_routes) then
    return nil
  end

  local endpoint_info = M.extract_endpoint_info(content, file_path, tonumber(line_number))
  if not endpoint_info then
    return nil
  end

  -- Always skip routes.rb results to focus on controller actions
  -- Routes are auto-generated from controllers in standard Rails
  if is_routes then
    return nil
  end

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
    display_value = endpoint_info.method .. " " .. endpoint_info.path,
  }
end

-- Extract endpoint information from Rails code
function M.extract_endpoint_info(content, file_path, line_number)
  -- Handle controller actions
  if file_path:match("controller") then
    return M.extract_controller_action(content, file_path, line_number)
  end
  
  -- Handle routes.rb definitions  
  if file_path:match("routes%.rb") then
    return M.extract_route_definition(content)
  end

  return nil
end

-- Extract controller action information
function M.extract_controller_action(content, file_path, line_number)
  local action = content:match("def (%w+)")
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
    destroy = "DELETE"
  }

  -- For custom actions, try to infer from common patterns
  local method = action_method_map[action]
  if not method then
    -- Common patterns for custom actions
    if action:match("create") or action:match("add") or action:match("register") then
      method = "POST"
    elseif action:match("update") or action:match("edit") or action:match("modify") then
      method = "PATCH"
    elseif action:match("delete") or action:match("remove") or action:match("destroy") then
      method = "DELETE"
    else
      method = "GET" -- Default for custom actions like 'profile', 'search', etc.
    end
  end
  
  -- Generate path based on controller and action
  local controller_name = M.extract_controller_name(file_path)
  local path = M.generate_action_path(controller_name, action, file_path)

  return {
    method = method,
    path = path
  }
end

-- Extract route definition from routes.rb
function M.extract_route_definition(content)
  -- Match explicit route definitions like: get '/users', to: 'users#index'
  local route_method, route_path = content:match("(%w+)%s+['\"]([^'\"]+)['\"]")
  if route_method and route_path then
    return {
      method = route_method:upper(),
      path = route_path
    }
  end

  -- For resources and namespace, we should not return results here
  -- as they don't represent actual endpoints - they generate endpoints
  -- that are handled by controller actions
  return nil
end

-- Extract controller name from file path
function M.extract_controller_name(file_path)
  -- Extract from path like: app/controllers/users_controller.rb
  local controller = file_path:match("app/controllers/(.*)_controller%.rb$")
  if controller then
    -- Handle nested controllers like admin/users -> admin/users
    return controller
  end
  
  -- Handle API controllers: app/controllers/api/v1/users_controller.rb
  controller = file_path:match("app/controllers/(.*)%.rb$")
  if controller then
    controller = controller:gsub("_controller", "")
    return controller
  end

  return "unknown"
end

-- Generate action path based on Rails conventions
function M.generate_action_path(controller_name, action, file_path)
  -- Handle API controllers
  if file_path:match("app/controllers/api/") then
    local api_path = file_path:match("app/controllers/(api/.*/).*_controller%.rb")
    if api_path then
      api_path = "/" .. api_path:gsub("/$", "")
      local resource = controller_name:gsub(".*_", "") -- Get last part after underscore
      local base_path = api_path .. resource
      
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
  end

  -- Handle regular controllers  
  local resource = controller_name:gsub("_", "/")
  local base_path = "/" .. resource

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

return M
