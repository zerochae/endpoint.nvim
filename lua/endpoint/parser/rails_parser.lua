local Parser = require "endpoint.core.Parser"

---@class endpoint.RailsParser
---Rails-specific parser for route files and controller actions
local RailsParser = Parser:extend()

-- ========================================
-- PUBLIC METHODS
-- ========================================

---Creates a new RailsParser instance
function RailsParser:new()
  RailsParser.super.new(self, {
    parser_name = "rails_parser",
    framework_name = "rails",
    language = "ruby",
  })
end

---Extracts base path from Rails route content (for explicit routes)
function RailsParser:extract_base_path(file_path, line_number)
  -- For Rails, base paths are usually determined by namespace context
  return self:_find_namespace_prefix(file_path, line_number)
end

---Extracts endpoint path from Rails content
function RailsParser:extract_endpoint_path(content, file_path, line_number)
  -- Handle multiline patterns by normalizing whitespace
  local normalized_content = content:gsub("%s+", " "):gsub("[\r\n]+", " ")

  -- Extract path from explicit routes: get '/path', post '/path', etc. or multiline equivalent
  local path = normalized_content:match "['\"]([^'\"]+)['\"]"
  if path then
    return path
  end

  -- Only process action patterns if NOT in member/collection context
  if file_path and line_number and self:_is_in_member_collection_context(file_path, line_number) then
    return nil -- Skip member/collection routes - they should be handled by resources processing
  end

  -- Pattern for member/collection routes: get :action_name or multiline equivalent
  local action_name = normalized_content:match ":([%w_]+)"
  if action_name then
    return "/" .. action_name
  end

  return nil
end

---Extracts HTTP method from Rails content
function RailsParser:extract_method(content)
  return self:_extract_http_method(content)
end

function RailsParser:parse_content(content, file_path, line_number, column)
  -- Only process if this looks like Rails routes or controller code
  if not self:is_content_valid_for_parsing(content) then
    return nil
  end

  -- Handle routes.rb files for resource discovery
  if file_path and file_path:match "routes%.rb$" then
    -- Process resources routes first (they generate multiple endpoints)
    local resources_results = self:_process_resources_route(content, file_path, line_number, column)
    if resources_results then
      return resources_results
    end

    -- Check for nested routes
    local nested_results = self:_process_nested_routes(content, file_path, line_number, column)
    if nested_results then
      return nested_results
    end

    -- Skip other routes.rb content for line-by-line parsing
    return nil
  end

  -- For controller files, check for controller actions
  if file_path and file_path:match "controllers/.*%.rb$" then
    local controller_result = self:_process_controller_action(content, file_path, line_number, column)
    if controller_result then
      return controller_result
    end
  end

  -- Fall back to parent implementation for single endpoint parsing
  return Parser.parse_content(self, content, file_path, line_number, column)
end

---Validates if content contains Rails annotations
function RailsParser:is_content_valid_for_parsing(content)
  if not Parser.is_content_valid_for_parsing(self, content) then
    return false
  end

  -- Check if content contains Rails route or controller patterns
  if not self:_is_rails_content(content) then
    return false
  end

  -- Additional validation for Rails-specific filtering
  return self:_is_valid_route_line(content)
end

---Gets parsing confidence for Rails content
function RailsParser:get_parsing_confidence(content)
  if not self:is_content_valid_for_parsing(content) then
    return 0.0
  end

  local base_confidence = 0.7
  local confidence_boost = 0

  -- Boost for explicit route definitions
  if content:match "to:%s*['\"]" then
    confidence_boost = confidence_boost + 0.2
  end

  -- Boost for resource definitions
  if content:match "resources?%s+:" then
    confidence_boost = confidence_boost + 0.15
  end

  -- Boost for controller actions in proper file structure
  if content:match "def%s+[%w_]+" then
    confidence_boost = confidence_boost + 0.1
  end

  return math.min(base_confidence + confidence_boost, 1.0)
end

-- ========================================
-- PRIVATE METHODS
-- ========================================

---Extracts HTTP method from Rails route content
function RailsParser:_extract_http_method(content)
  -- Handle multiline patterns by normalizing whitespace
  local normalized_content = content:gsub("%s+", " "):gsub("[\r\n]+", " ")

  -- Match HTTP verbs at the start of line followed by space (with optional leading whitespace)
  local route_method = normalized_content:match "^%s*(%w+)%s+"
  if route_method then
    -- Only accept valid HTTP verbs
    local valid_methods = {
      get = true,
      post = true,
      put = true,
      delete = true,
      patch = true,
      head = true,
      options = true,
    }
    if valid_methods[route_method:lower()] then
      return route_method:upper()
    end
  end

  -- Special case for root routes or multiline equivalent
  if normalized_content:match "root%s" then
    return "GET"
  end

  return nil
end

---Checks if content represents a valid Rails route line
function RailsParser:_is_valid_route_line(content)
  -- Allow method definitions (controller actions) but filter out other patterns
  if content:match "def%s+%w+" then
    return true -- Allow controller action definitions
  end

  return not (
    content:match "@%w+%s*=" -- Assignment like @post =
    or content:match "%.%w+" -- Method calls like Post.find
    or content:match "params%[" -- params[:id] references
    or content:match "^%s*#" -- Comments
    or content:match "require" -- require statements
    or content:match "include" -- include statements
  )
end

---Checks if an action name represents a private helper method
function RailsParser:_is_private_helper_method(action_name)
  local PRIVATE_METHOD_PREFIXES = {
    set_ = true,
    find_ = true,
    check_ = true,
    ensure_ = true,
    verify_ = true,
    load_ = true,
    init_ = true,
    params = true,
    permitted = true,
    current_ = true,
    authenticate = true,
    authorize = true,
    redirect = true,
    handle = true,
    build = true,
    setup = true,
    validate = true,
  }

  local PRIVATE_METHOD_SUFFIXES = {
    "_params$",
    "_permitted$",
    "^current_",
    "^authenticate",
    "^authorize",
    "^redirect_",
    "^handle_",
    "^build_",
    "^setup_",
    "^validate_",
  }

  -- Check prefixes
  for prefix, _ in pairs(PRIVATE_METHOD_PREFIXES) do
    if action_name:match("^" .. prefix) then
      return true
    end
  end

  -- Check suffixes
  for _, pattern in ipairs(PRIVATE_METHOD_SUFFIXES) do
    if action_name:match(pattern) then
      return true
    end
  end

  return false
end

---Processes controller action definitions
function RailsParser:_process_controller_action(content, file_path, line_number, column)
  if not file_path:match "controllers/.*%.rb$" then
    return nil
  end

  local action_name = content:match "def%s+([%w_]+)"
  if
    not action_name
    or self:_is_private_helper_method(action_name)
    or self:_is_private_method(file_path, line_number)
  then
    return nil
  end

  -- Process all actions including standard CRUD actions
  -- Standard CRUD actions are important for endpoint discovery

  -- Map Rails controller actions to HTTP methods (following Rails 7+ conventions)
  local action_to_method = {
    index = "GET",
    show = "GET",
    new = "GET",
    edit = "GET",
    create = "POST",
    update = "PATCH", -- Rails uses PATCH by default for updates (Rails 7+ convention)
    destroy = "DELETE",
  }

  -- For custom actions, try to infer from common patterns
  local method = action_to_method[action_name]
  if not method then
    -- Common patterns for custom actions
    if action_name:match "create" or action_name:match "add" or action_name:match "register" then
      method = "POST"
    elseif action_name:match "update" or action_name:match "edit" or action_name:match "modify" then
      method = "PATCH"
    elseif action_name:match "delete" or action_name:match "remove" or action_name:match "destroy" then
      method = "DELETE"
    else
      method = "GET" -- Default for custom actions like 'profile', 'search', etc.
    end
  end

  local controller_path = file_path:match "controllers/(.*)_controller%.rb$"
  local controller_name = "unknown"
  local namespace_path = ""

  if controller_path then
    if controller_path:match "/" then
      local parts = {}
      for part in controller_path:gmatch "[^/]+" do
        table.insert(parts, part)
      end
      controller_name = parts[#parts]
      for i = 1, #parts - 1 do
        namespace_path = namespace_path .. "/" .. parts[i]
      end
    else
      controller_name = controller_path
    end
  end

  local base_path = namespace_path .. "/" .. controller_name
  local endpoint_path
  if action_name == "index" then
    endpoint_path = base_path
  elseif action_name == "show" or action_name == "update" or action_name == "destroy" then
    endpoint_path = base_path .. "/:id"
  elseif action_name == "edit" then
    endpoint_path = base_path .. "/:id/edit"
  elseif action_name == "new" then
    endpoint_path = base_path .. "/new"
  elseif action_name == "create" then
    endpoint_path = base_path -- create uses base path without /create suffix
  else
    -- Custom actions: determine if member or collection based on routes.rb
    local is_member_route = self:_is_member_route(controller_name, action_name)
    if is_member_route then
      -- Member routes: require ID
      endpoint_path = base_path .. "/:id/" .. action_name
    else
      -- Collection routes: no ID required
      endpoint_path = base_path .. "/" .. action_name
    end
  end

  return {
    method = method,
    endpoint_path = endpoint_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = method .. "[" .. controller_name .. "#" .. action_name .. "] " .. endpoint_path,
    confidence = 0.8,
    tags = { "ruby", "rails", "controller_action" },
    metadata = self:create_metadata("controller_action", {
      controller_name = controller_name,
      action_name = action_name,
    }, content),
  }
end

---Processes resources/resource route definitions
function RailsParser:_process_resources_route(content, file_path, line_number, column)
  if not file_path:match "routes%.rb$" then
    return nil
  end

  -- Handle multiple resources: resources :users, :products, :orders
  local resource_type = content:match "^%s*(resources?)%s+"
  if not resource_type then
    return nil
  end

  local all_endpoints = {}

  -- Extract all resource names (handling both single and multiple)
  local resource_names = {}

  -- More specific pattern to extract resource names only from the start of resources declaration
  -- This avoids matching symbols in except/only clauses

  -- First, extract the part before any options (only:, except:, do)
  local main_part = content:match "^%s*resources?%s+(.+)$"
  if main_part then
    -- Clean up the main part by removing any trailing options and 'do'
    main_part = main_part:gsub("%s*do%s*$", "") -- remove trailing 'do'
    main_part = main_part:gsub("%s*,%s*only:.*$", "") -- remove only clause
    main_part = main_part:gsub("%s*,%s*except:.*$", "") -- remove except clause

    -- Now extract resource names from the cleaned part
    for resource_name in main_part:gmatch ":([%w_]+)" do
      table.insert(resource_names, resource_name)
    end
  end

  if #resource_names == 0 then
    return nil
  end

  -- Find namespace prefix
  local namespace_prefix = self:_find_namespace_prefix(file_path, line_number)

  for _, resource_name in ipairs(resource_names) do
    -- Extract only/except clauses
    local only_actions = {}
    local except_actions = {}

    -- Handle both :symbol syntax and %i[] syntax for only/except clauses
    local only_clause = content:match "only:%s*%[([^%]]+)%]" or content:match "only:%s*%%i%[([^%]]+)%]"
    if only_clause then
      -- Handle both :symbol and word syntax
      for action in only_clause:gmatch ":([%w_]+)" do
        only_actions[action] = true
      end
      for action in only_clause:gmatch "([%w_]+)" do
        if not action:match "^:" then -- Skip if it starts with :, already processed
          only_actions[action] = true
        end
      end
    end

    local except_clause = content:match "except:%s*%[([^%]]+)%]" or content:match "except:%s*%%i%[([^%]]+)%]"
    if except_clause then
      -- Handle both :symbol and word syntax
      for action in except_clause:gmatch ":([%w_]+)" do
        except_actions[action] = true
      end
      for action in except_clause:gmatch "([%w_]+)" do
        if not action:match "^:" then -- Skip if it starts with :, already processed
          except_actions[action] = true
        end
      end
    end

    -- Generate all CRUD endpoints for this resource
    local base_path = namespace_prefix .. "/" .. resource_name

    local crud_actions = {
      { action = "index", method = "GET", path = base_path },
      { action = "new", method = "GET", path = base_path .. "/new" },
      { action = "create", method = "POST", path = base_path },
      { action = "show", method = "GET", path = base_path .. "/:id" },
      { action = "edit", method = "GET", path = base_path .. "/:id/edit" },
      { action = "update", method = "PATCH", path = base_path .. "/:id" },
      { action = "destroy", method = "DELETE", path = base_path .. "/:id" },
    }

    -- If it's singular resource, skip index and modify paths
    if resource_type == "resource" then
      crud_actions = {
        { action = "new", method = "GET", path = base_path .. "/new" },
        { action = "create", method = "POST", path = base_path },
        { action = "show", method = "GET", path = base_path },
        { action = "edit", method = "GET", path = base_path .. "/edit" },
        { action = "update", method = "PATCH", path = base_path },
        { action = "destroy", method = "DELETE", path = base_path },
      }
    end

    for _, crud in ipairs(crud_actions) do
      local should_include = true

      -- Check only clause
      if next(only_actions) and not only_actions[crud.action] then
        should_include = false
      end

      -- Check except clause
      if except_actions[crud.action] then
        should_include = false
      end

      if should_include then
        -- Find controller action
        local controller_info = self:_find_controller_action(resource_name, crud.action)
        local target_file = controller_info and controller_info.file_path or file_path
        local target_line = controller_info and controller_info.line_number or line_number

        table.insert(all_endpoints, {
          method = crud.method,
          endpoint_path = crud.path,
          file_path = target_file,
          line_number = target_line,
          column = column,
          display_value = crud.method .. "[" .. resource_name .. "#" .. crud.action .. "] " .. crud.path,
          confidence = 0.9,
          tags = { "ruby", "rails", "resource" },
          metadata = self:create_metadata(
            resource_type == "resource" and "singular_resource" or "collection_resource",
            {
              resource_name = resource_name,
              action_name = crud.action,
            },
            content
          ),
        })
      end
    end
  end

  return #all_endpoints > 0 and all_endpoints or nil
end

---Processes nested resources (resources :comments inside resources :posts)
function RailsParser:_process_nested_routes(content, file_path, line_number, column)
  if not file_path:match "routes%.rb$" then
    return nil
  end

  local nested_match = content:match "resources%s+:([%w_]+).*except:%s*%[([^%]]+)%]"
  if not nested_match then
    nested_match = content:match "resources%s+:([%w_]+)"
  end

  if not nested_match then
    return nil
  end

  local resource_name = nested_match
  local parent_resource = self:_find_parent_resource(file_path, line_number)
  if not parent_resource then
    return nil
  end

  -- Only process truly nested resources (must be indented and inside a resources block)
  if vim.fn.filereadable(file_path) == 0 then
    return nil
  end

  local read_file_path = vim.fn.readfile(file_path) or {}
  if #read_file_path == 0 or line_number > #read_file_path then
    return nil
  end

  local current_line = read_file_path[line_number]
  -- Must be indented to be truly nested
  if not current_line:match "^%s%s+" then
    return nil -- Not indented enough to be nested
  end

  local endpoints = {}
  local base_path = "/" .. parent_resource .. "/:" .. parent_resource:sub(1, -2) .. "_id/" .. resource_name

  -- Standard CRUD actions for nested resources
  local crud_actions = {
    { method = "GET", path = base_path, action = "index" },
    { method = "GET", path = base_path .. "/new", action = "new" },
    { method = "POST", path = base_path, action = "create" },
    { method = "GET", path = base_path .. "/:id", action = "show" },
    { method = "GET", path = base_path .. "/:id/edit", action = "edit" },
    { method = "PUT", path = base_path .. "/:id", action = "update" },
    { method = "DELETE", path = base_path .. "/:id", action = "destroy" },
  }

  -- Check for except clause
  local except_actions = {}
  local except_clause = read_file_path:match "except:%s*%[([^%]]+)%]"
  if except_clause then
    for action in except_clause:gmatch ":([%w_]+)" do
      except_actions[action] = true
    end
  end

  -- Check for only clause
  local only_actions = {}
  local only_clause = read_file_path:match "only:%s*%[([^%]]+)%]"
  if only_clause then
    for action in only_clause:gmatch ":([%w_]+)" do
      only_actions[action] = true
    end
  end

  for _, crud in ipairs(crud_actions) do
    local should_include = true

    if next(only_actions) and not only_actions[crud.action] then
      should_include = false
    end

    if except_actions[crud.action] then
      should_include = false
    end

    if should_include then
      -- Find the controller action for this nested route
      local controller_info = self:_find_controller_action(resource_name, crud.action)
      local target_file = controller_info and controller_info.file_path or file_path
      local target_line = controller_info and controller_info.line_number or line_number
      local target_column = controller_info and controller_info.column or column

      table.insert(endpoints, {
        method = crud.method,
        endpoint_path = crud.path,
        file_path = target_file,
        line_number = target_line,
        column = target_column,
        display_value = crud.method .. "[" .. resource_name .. "#" .. crud.action .. "] " .. crud.path,
        confidence = 0.9,
        tags = { "ruby", "rails", "nested_route" },
        metadata = self:create_metadata("nested_resource", {
          resource_name = resource_name,
          parent_resource = parent_resource,
          action_name = crud.action,
        }, read_file_path),
      })
    end
  end

  return #endpoints > 0 and endpoints or nil
end

---Find namespace prefix for the current line
function RailsParser:_find_namespace_prefix(file_path, line_number)
  if vim.fn.filereadable(file_path) == 0 then
    return ""
  end

  local content = vim.fn.readfile(file_path) or {}
  if #content == 0 then
    return ""
  end

  local namespaces = {}
  local depth = 0

  -- Search backwards from current line to find namespace blocks
  for i = line_number - 1, 1, -1 do
    local line = content[i]

    -- Count 'end' statements (going backwards, so 'end' increases depth)
    if line:match "^%s*end%s*$" then
      depth = depth + 1
    -- Found a 'do' block - check what type
    elseif line:match "%s+do%s*$" then
      if line:match "namespace%s+:([%w_]+)%s+do" then
        -- This is a namespace block
        local namespace_name = line:match "namespace%s+:([%w_]+)"
        if depth == 0 then
          -- This is an active namespace for our line
          table.insert(namespaces, 1, namespace_name)
        else
          -- Deeper nested block, reduce depth and continue
          depth = depth - 1
        end
      else
        -- Other 'do' blocks (resources, member, collection, etc.)
        depth = depth - 1
      end
    elseif line:match "Rails%.application%.routes%.draw" then
      break
    end
  end

  if #namespaces > 0 then
    return "/" .. table.concat(namespaces, "/")
  else
    return ""
  end
end

---Find the parent resource for a member/collection route
function RailsParser:_find_parent_resource(file_path, line_number)
  local file = io.open(file_path, "r")
  if not file then
    return nil
  end

  local content = {}
  for line in file:lines() do
    table.insert(content, line)
  end
  file:close()

  if #content == 0 then
    return nil
  end

  -- Track nesting depth to properly handle nested structures
  local depth = 0

  -- Search backwards from current line to find the parent resources block
  for i = line_number - 1, 1, -1 do
    local line = content[i]

    -- Count 'end' statements (going backwards, so 'end' increases depth)
    if line:match "^%s*end%s*$" then
      depth = depth + 1
    -- Found a 'do' block - check what type
    elseif line:match "%s+do%s*$" then
      -- Check if this is a resources block with 'do'
      local resource_name = line:match "^%s*resources%s+:([%w_]+)%s+do"
      if resource_name then
        if depth == 0 then
          -- This is the immediate parent resources block
          return resource_name
        else
          -- Deeper nested block, reduce depth and continue
          depth = depth - 1
        end
      else
        -- Other 'do' blocks (member, collection, namespace, etc.)
        if depth > 0 then
          depth = depth - 1
        end
      end
    -- Check for resources without 'do' (single line resources)
    elseif depth == 0 then
      local resource_name = line:match "^%s*resources%s+:([%w_]+)"
      if resource_name and not line:match "except:" and not line:match "only:" then
        -- Found a parent resources declaration
        return resource_name
      end
    end

    -- If we hit the start of routes, stop searching
    if line:match "Rails%.application%.routes%.draw" then
      break
    end
  end

  return nil
end

---Find the controller action implementation for a given action
function RailsParser:_find_controller_action(resource_name, action_name)
  -- Convert resource name to controller path
  local controller_file = "app/controllers/" .. resource_name .. "_controller.rb"

  -- Try different possible paths
  local possible_paths = {
    controller_file,
    "tests/fixtures/rails/" .. controller_file,
  }

  local actual_file = nil
  for _, path in ipairs(possible_paths) do
    local file = io.open(path, "r")
    if file then
      file:close()
      actual_file = path
      break
    end
  end

  if not actual_file then
    return nil
  end

  local file = io.open(actual_file, "r")
  if not file then
    return nil
  end

  local content = {}
  for line in file:lines() do
    table.insert(content, line)
  end
  file:close()

  if #content == 0 then
    return nil
  end

  -- Search for the action definition
  for i, line in ipairs(content) do
    if line:match("def%s+" .. action_name .. "%s*$") or line:match("def%s+" .. action_name .. "%s*%(") then
      -- Find the column where 'def' starts
      local def_start = line:find "def"
      return {
        file_path = actual_file,
        line_number = i,
        column = def_start or 1,
      }
    end
  end

  return nil
end

---Check if a method is in the private section of a Rails controller
function RailsParser:_is_private_method(file_path, line_number)
  if vim.fn.filereadable(file_path) == 0 then
    return false
  end

  local content = vim.fn.readfile(file_path) or {}
  if #content == 0 then
    return false
  end
  local in_private = false

  -- Search backwards from current line to find private keyword
  for i = line_number - 1, 1, -1 do
    local line = content[i]

    -- Found private keyword
    if line:match "^%s*private%s*$" then
      in_private = true
      break
    end

    -- If we hit another public method or class definition, stop
    if line:match "^%s*def%s+[%w_]+" and not line:match "^%s*def%s+initialize" then
      -- Check if there's a private keyword before this method
      for j = i - 1, 1, -1 do
        local prev_line = content[j]
        if prev_line and prev_line:match "^%s*private%s*$" then
          in_private = true
          break
        elseif prev_line and (prev_line:match "^%s*def%s+[%w_]+" or prev_line:match "^%s*class%s+") then
          break
        end
      end
      break
    end

    -- If we hit class definition, stop
    if line:match "^%s*class%s+" then
      break
    end
  end

  return in_private
end

---Checks if the current line is within a member or collection block
function RailsParser:_is_in_member_collection_context(file_path, line_number)
  if not file_path or not line_number or vim.fn.filereadable(file_path) == 0 then
    return false
  end

  local content = vim.fn.readfile(file_path) or {}
  if #content == 0 or line_number > #content then
    return false
  end

  -- Search backwards from current line to find member/collection context
  local depth = 0
  for i = line_number - 1, 1, -1 do
    local line = content[i]

    -- Count 'end' statements (going backwards, so 'end' increases depth)
    if line:match "^%s*end%s*$" then
      depth = depth + 1
    -- Found a 'do' block - check what type
    elseif line:match "%s+do%s*$" then
      if line:match "member%s+do" or line:match "collection%s+do" then
        -- This is a member/collection block
        if depth == 0 then
          -- We are directly inside this member/collection block
          return true
        else
          -- Deeper nested block, reduce depth and continue
          depth = depth - 1
        end
      else
        -- Other 'do' blocks (resources, namespace, etc.)
        depth = depth - 1
      end
    elseif line:match "Rails%.application%.routes%.draw" then
      break
    end
  end

  return false
end

---Checks if content looks like Rails routing or controller code
function RailsParser:_is_rails_content(content)
  -- Handle multiline patterns by normalizing whitespace
  local normalized_content = content:gsub("%s+", " "):gsub("[\r\n]+", " ")

  return normalized_content:match "Rails%.application%.routes%.draw"
    or normalized_content:match "^%s*get%s" -- HTTP verbs must be at start of line (with optional whitespace)
    or normalized_content:match "^%s*post%s"
    or normalized_content:match "^%s*put%s"
    or normalized_content:match "^%s*delete%s"
    or normalized_content:match "^%s*patch%s"
    or normalized_content:match "^%s*head%s"
    or normalized_content:match "^%s*options%s"
    or normalized_content:match "resources%s" -- Resources can be anywhere
    or normalized_content:match "resource%s"
    or normalized_content:match "namespace%s"
    or normalized_content:match "scope%s"
    or normalized_content:match "root%s"
    or normalized_content:match "def%s+[%w_]+" -- Method definitions
end

---Checks if a controller has resources defined in routes.rb
function RailsParser:_has_resources_defined(resource_name)
  -- Find the routes.rb file
  local routes_file = "config/routes.rb"
  if vim.fn.filereadable(routes_file) == 0 then
    routes_file = "tests/fixtures/rails/config/routes.rb"
    if vim.fn.filereadable(routes_file) == 0 then
      return false
    end
  end

  local lines = vim.fn.readfile(routes_file) or {}

  for _, line in ipairs(lines) do
    -- Check for resources declarations for this resource
    if line:match("resources%s+:" .. resource_name) or line:match("resource%s+:" .. resource_name) then
      return true
    end
  end

  return false
end

---Checks if an action is defined as a member route in routes.rb
function RailsParser:_is_member_route(controller_name, action_name)
  -- Find the routes.rb file
  local routes_file = "config/routes.rb"
  if vim.fn.filereadable(routes_file) == 0 then
    routes_file = "tests/fixtures/rails/config/routes.rb"
    if vim.fn.filereadable(routes_file) == 0 then
      -- Default to collection route if routes.rb not found
      return false
    end
  end

  local lines = vim.fn.readfile(routes_file) or {}
  local in_resources_block = false
  local in_member_block = false
  local in_collection_block = false
  local resource_name = controller_name

  for _, line in ipairs(lines) do
    -- Check if we're entering the correct resources block
    if line:match("resources%s+:" .. resource_name) then
      in_resources_block = true
    elseif in_resources_block and line:match "^%s*end%s*$" then
      -- Exiting resources block
      in_resources_block = false
      in_member_block = false
      in_collection_block = false
    elseif in_resources_block then
      -- Check for member/collection blocks
      if line:match "member%s+do" then
        in_member_block = true
        in_collection_block = false
      elseif line:match "collection%s+do" then
        in_collection_block = true
        in_member_block = false
      elseif line:match "^%s*end%s*$" then
        in_member_block = false
        in_collection_block = false
      elseif in_member_block and line:match(":" .. action_name) then
        return true
      elseif in_collection_block and line:match(":" .. action_name) then
        return false
      end
    end
  end

  -- Default to collection route if not found in member block
  return false
end

return RailsParser
