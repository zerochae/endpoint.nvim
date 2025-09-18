local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
local rg = require "endpoint.utils.rg"

---@class endpoint.RailsFramework
local RailsFramework = setmetatable({}, { __index = Framework })
RailsFramework.__index = RailsFramework

---Creates a new RailsFramework instance
function RailsFramework:new()
  local rails_framework_instance = setmetatable({}, self)
  rails_framework_instance.name = "rails"
  -- Define common patterns to avoid duplication
  local route_patterns = { "get\\s+", "post\\s+", "put\\s+", "patch\\s+", "delete\\s+" }
  local resource_patterns = { "resources\\s+:", "resource\\s+:" }
  local action_patterns = {
    "def\\s+index\\b",
    "def\\s+show\\b",
    "def\\s+create\\b",
    "def\\s+update\\b",
    "def\\s+destroy\\b",
  }

  rails_framework_instance.config = {
    file_extensions = { "*.rb" },
    exclude_patterns = { "**/vendor", "**/tmp", "**/log", "**/.bundle" },
    patterns = {
      GET = { route_patterns[1], resource_patterns[1], resource_patterns[2], action_patterns[1], action_patterns[2] },
      POST = { route_patterns[2], resource_patterns[1], resource_patterns[2], action_patterns[3] },
      PUT = { route_patterns[3], resource_patterns[1], action_patterns[4] },
      PATCH = { route_patterns[4], resource_patterns[1], action_patterns[4] },
      DELETE = { route_patterns[5], resource_patterns[1], action_patterns[5] },
    },
    search_options = { "--type", "ruby" },
  }

  rails_framework_instance:_validate_config()
  rails_framework_instance:_initialize()
  return rails_framework_instance
end

---Extracts HTTP method from Rails route content
local function extract_http_method(content)
  if content:match "get%s" then
    return "GET"
  elseif content:match "post%s" then
    return "POST"
  elseif content:match "put%s" then
    return "PUT"
  elseif content:match "patch%s" then
    return "PATCH"
  elseif content:match "delete%s" then
    return "DELETE"
  elseif content:match "root%s" then
    return "GET"
  else
    return nil
  end
end

---Checks if content represents a valid Rails route line
local function is_valid_route_line(content)
  return not (
    content:match "@%w+%s*=" -- Assignment like @post =
    or content:match "%.%w+" -- Method calls like Post.find
    or content:match "params%[" -- params[:id] references
    or content:match "^%s*#" -- Comments
    or content:match "require" -- require statements
    or content:match "include" -- include statements
    or content:match "def%s+%w+" -- method definitions
  )
end

-- Private method patterns for filtering
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

---Checks if an action name represents a private helper method
local function is_private_helper_method(action_name)
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

---Processes Rails explicit routes (get, post, put, etc.)
function RailsFramework:_process_explicit_route(content, file_path, line_number, column)
  if not is_valid_route_line(content) then
    return nil
  end

  local route_method = extract_http_method(content)
  if not route_method then
    return nil
  end

  local route_path = content:match "['\"]([^'\"]+)['\"]"

  -- Pattern for member/collection routes: get :action_name
  if not route_path then
    local action_name = content:match ":([%w_]+)"
    if action_name then
      local parent_resource = RailsFramework._find_parent_resource(file_path, line_number)
      if parent_resource then
        local is_member = RailsFramework._is_in_member_block(file_path, line_number)
        local is_collection = RailsFramework._is_in_collection_block(file_path, line_number)

        if is_member or is_collection then
          local controller_info = RailsFramework._find_controller_action(parent_resource, action_name)
          if controller_info then
            route_path = is_member and ("/" .. parent_resource .. "/:id/" .. action_name)
              or ("/" .. parent_resource .. "/" .. action_name)
            return {
              method = route_method,
              endpoint_path = self._clean_rails_path(route_path),
              file_path = controller_info.file_path,
              line_number = controller_info.line_number,
              column = 1,
              display_value = route_method .. "[" .. parent_resource .. "#" .. action_name .. "] " .. self._clean_rails_path(route_path),
              confidence = 0.9,
              tags = { "ruby", "rails", "route", "member_action" },
              metadata = {
                framework_version = "rails",
                language = "ruby",
                route_type = is_member and "member" or "collection",
                resource_name = parent_resource,
                action_name = action_name,
              },
            }
          end
        end

        route_path = is_member and ("/" .. parent_resource .. "/:id/" .. action_name)
          or is_collection and ("/" .. parent_resource .. "/" .. action_name)
          or ("/" .. action_name)
      else
        route_path = "/" .. action_name
      end
    end
  end

  if not route_method or not route_path then
    if content:match "root%s+" then
      -- Extract controller#action from root 'controller#action'
      local controller_action = content:match "root%s+['\"]([%w_]+#[%w_]+)['\"]"
      local display_text = controller_action and ("GET[" .. controller_action .. "] /") or "GET /"

      return {
        method = "GET",
        endpoint_path = "/",
        file_path = file_path,
        line_number = line_number,
        column = column,
        display_value = display_text,
        confidence = 0.9,
        tags = { "ruby", "rails", "route" },
        metadata = {
          framework_version = "rails",
          language = "ruby",
          route_type = "root",
          controller_action = controller_action,
        },
      }
    end
    return nil
  end

  -- Extract controller and action from "to: 'controller#action'" pattern
  local controller_action = content:match "to:%s*['\"]([%w_]+#[%w_]+)['\"]"
  local display_text = controller_action and (route_method:upper() .. "[" .. controller_action .. "] " .. route_path)
                       or (route_method:upper() .. " " .. route_path)

  return {
    method = route_method:upper(),
    endpoint_path = route_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = display_text,
    confidence = 0.9,
    tags = { "ruby", "rails", "route" },
    metadata = {
      framework_version = "rails",
      language = "ruby",
      route_type = "explicit",
      controller_action = controller_action,
    },
  }
end

---Processes Rails controller actions (def index, def show, etc.)
function RailsFramework:_process_controller_action(content, file_path, line_number, column)
  if not file_path:match "controllers/.*%.rb$" then
    return nil
  end

  local action_name = content:match "def%s+([%w_]+)"
  if not action_name or is_private_helper_method(action_name) or self._is_private_method(file_path, line_number) then
    return nil
  end

  local action_to_method = {
    index = "GET",
    show = "GET",
    new = "GET",
    edit = "GET",
    create = "POST",
    update = "PUT",
    destroy = "DELETE",
  }
  local method = action_to_method[action_name] or "GET"

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
  local endpoint_path = action_name == "index" and base_path
    or (action_name == "show" or action_name == "edit" or action_name == "update" or action_name == "destroy") and (base_path .. "/:id")
    or action_name == "new" and (base_path .. "/new")
    or (base_path .. "/" .. action_name)

  return {
    method = method,
    endpoint_path = endpoint_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = method .. "[" .. controller_name .. "#" .. action_name .. "] " .. endpoint_path,
    confidence = 0.8,
    tags = { "ruby", "rails", "controller_action" },
    metadata = {
      framework_version = "rails",
      language = "ruby",
      controller_name = controller_name,
      action_name = action_name,
      route_type = "controller_action",
    },
  }
end

---Processes Rails namespace declarations (namespace :api do)
function RailsFramework:_process_namespace(content, file_path, line_number, column)
  if not file_path:match "routes%.rb$" then
    return nil
  end

  local namespace_name = content:match "namespace%s+:([%w_]+)%s+do"
  if not namespace_name then
    return nil
  end

  local endpoint_path = "/" .. namespace_name

  return {
    method = "GET",
    endpoint_path = endpoint_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = "NAMESPACE " .. endpoint_path,
    confidence = 0.7,
    tags = { "ruby", "rails", "namespace" },
    metadata = {
      framework_version = "rails",
      language = "ruby",
      route_type = "namespace",
      namespace_name = namespace_name,
    },
  }
end

---Processes nested resources (resources :comments inside resources :posts)
function RailsFramework:_process_nested_routes(content, file_path, line_number, column)
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
  local parent_resource = RailsFramework._find_parent_resource(file_path, line_number)
  if not parent_resource then
    return nil
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
  local except_clause = content:match "except:%s*%[([^%]]+)%]"
  if except_clause then
    for action in except_clause:gmatch ":([%w_]+)" do
      except_actions[action] = true
    end
  end

  -- Check for only clause
  local only_actions = {}
  local only_clause = content:match "only:%s*%[([^%]]+)%]"
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
      local controller_info = RailsFramework._find_controller_action(resource_name, crud.action)
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
        metadata = {
          framework_version = "rails",
          language = "ruby",
          resource_name = resource_name,
          parent_resource = parent_resource,
          action_name = crud.action,
          route_type = "nested_resource",
        },
      })
    end
  end

  return #endpoints > 0 and endpoints or nil
end

---Validates the framework configuration
function RailsFramework:_validate_config()
  if not self.name then
    error "Framework name is required"
  end

  if not self.config.file_extensions then
    self.config.file_extensions = { "*.*" }
  end

  if not self.config.exclude_patterns then
    self.config.exclude_patterns = {}
  end
end

---Sets up detection and parsing for Rails
function RailsFramework:_initialize()
  -- Setup detector using file-based detection like the backup logic
  self.detector = DependencyDetector:new(
    { "rails", "actionpack", "railties" },
    { "Gemfile", "config/routes.rb", "config/application.rb", "app/controllers" },
    "rails_dependency_detection"
  )

  -- Rails framework uses direct parsing instead of RouteParser
  self.parser = nil
end


---Cleans Rails path patterns
function RailsFramework._clean_rails_path(path)
  if not path then
    return "/"
  end

  local cleaned = path

  -- Ensure path starts with /
  if not cleaned:match "^/" then
    cleaned = "/" .. cleaned
  end

  -- Remove trailing slash for consistency (except root)
  if cleaned ~= "/" and cleaned:match "/$" then
    cleaned = cleaned:gsub("/$", "")
  end

  return cleaned
end

---Detects if Rails is present in the current project
function RailsFramework:detect()
  if not self.detector then
    self:_initialize()
  end
  if self.detector then
    return self.detector:is_target_detected()
  end
  return false
end

---Parses Rails content to extract endpoint information
function RailsFramework:parse(content, file_path, line_number, column)
  -- Only process if this looks like Rails routes or controller code
  if
    not (
      content:match "Rails%.application%.routes%.draw"
      or content:match "get%s"
      or content:match "post%s"
      or content:match "put%s"
      or content:match "delete%s"
      or content:match "patch%s"
      or content:match "resources%s"
      or content:match "resource%s"
      or content:match "namespace%s"
      or content:match "scope%s"
      or content:match "root%s"
      or content:match "def%s+[%w_]+"
    )
  then
    return nil
  end

  -- Direct parsing approach
  local result = self:_process_explicit_route(content, file_path, line_number, column)
  if result then
    return result
  end

  -- Try namespace processing
  result = self:_process_namespace(content, file_path, line_number, column)
  if result then
    return result
  end

  -- Try controller action processing
  result = self:_process_controller_action(content, file_path, line_number, column)
  if result then
    return result
  end

  -- Fallback to parser if direct parsing fails
  if not self.parser then
    self:_initialize()
  end

  local parsed_endpoint = nil
  if self.parser then
    parsed_endpoint = self.parser:parse_content(content, file_path, line_number, column)
  end

  if parsed_endpoint then
    -- Enhance with additional Rails-specific metadata
    if not parsed_endpoint.tags then
      parsed_endpoint.tags = {}
    end

    -- Ensure Rails tags are present
    local has_ruby = false
    local has_rails = false
    for _, tag in ipairs(parsed_endpoint.tags) do
      if tag == "ruby" then
        has_ruby = true
      end
      if tag == "rails" then
        has_rails = true
      end
    end

    if not has_ruby then
      table.insert(parsed_endpoint.tags, "ruby")
    end
    if not has_rails then
      table.insert(parsed_endpoint.tags, "rails")
    end

    -- Set framework metadata
    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "rails"
    parsed_endpoint.metadata.language = "ruby"
  end

  return parsed_endpoint
end

---Gets the search command for finding all endpoints
function RailsFramework:get_search_cmd()
  if not self.config.patterns then
    error("Patterns not configured for framework: " .. self.name)
  end

  local search_options = {
    method_patterns = self.config.patterns,
    file_globs = self.config.file_extensions,
    exclude_globs = self.config.exclude_patterns,
    extra_flags = self.config.search_options or {},
  }

  return rg.create_command(search_options)
end

---Main template method for scanning endpoints
function RailsFramework:scan(options)
  options = options or {}

  local log = require "endpoint.utils.log"
  log.framework_debug("Starting scan with framework: " .. self.name)

  if not self:detect() then
    log.framework_debug("Framework not detected: " .. self.name)
    return {}
  end

  -- Get search command and execute it
  local search_cmd = self:get_search_cmd()
  local handle = io.popen(search_cmd)
  if not handle then
    return {}
  end
  local result = handle:read "*a"
  handle:close()

  local endpoints = {}
  for line in result:gmatch "[^\n]+" do
    local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
    if file_path and line_number and column and content then
      local line_num = tonumber(line_number)
      local col_num = tonumber(column)
      if line_num and col_num then
        -- Check for nested routes first
        local nested_results = self:_process_nested_routes(content, file_path, line_num, col_num)
        if nested_results then
          for _, nested_endpoint in ipairs(nested_results) do
            table.insert(endpoints, nested_endpoint)
          end
        else
          local endpoint = self:parse(content, file_path, line_num, col_num)
          if endpoint then
            table.insert(endpoints, endpoint)
          end
        end
      end
    end
  end

  log.framework_debug("Found " .. #endpoints .. " endpoints with " .. self.name)
  return endpoints
end

---Find the parent resource for a member/collection route
function RailsFramework._find_parent_resource(file_path, line_number)
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

  -- First check if we're in a member or collection block
  local in_member_collection = false
  local member_start = nil

  -- Search backwards to find member/collection block start
  for i = line_number - 1, 1, -1 do
    local line = content[i]
    if line:match "member%s+do" or line:match "collection%s+do" then
      in_member_collection = true
      member_start = i
      break
    elseif line:match "^%s*end%s*$" then
      break -- Hit an end before finding member/collection
    end
  end

  -- If we're in member/collection, search from that block start
  local search_start = in_member_collection and member_start or line_number

  -- Search backwards to find the containing resources block
  local depth = 0

  for i = (search_start or line_number) - 1, 1, -1 do
    local line = content[i]

    -- Count 'end' statements (going backwards, so 'end' increases depth)
    if line:match "^%s*end%s*$" then
      depth = depth + 1
    -- Found a 'do' block - check what type
    elseif line:match "%s+do%s*$" then
      if line:match "resources%s+:([%w_]+)%s+do" then
        -- This is a resources block with 'do'
        local resource_name = line:match "resources%s+:([%w_]+)"
        if depth == 0 then
          -- This is the immediate parent resource
          return resource_name
        else
          -- Deeper nested block, reduce depth and continue
          depth = depth - 1
        end
      else
        -- Other 'do' blocks (member, collection, namespace, etc.)
        depth = depth - 1
      end
    elseif line:match "Rails%.application%.routes%.draw" then
      break
    end
  end

  return nil
end

---Check if the current line is inside a member block
function RailsFramework._is_in_member_block(file_path, line_number)
  if vim.fn.filereadable(file_path) == 0 then
    return false
  end

  local content = vim.fn.readfile(file_path) or {}
  if #content == 0 then
    return false
  end
  local in_member_block = false

  -- Search backwards from current line
  for i = line_number - 1, 1, -1 do
    local line = content[i]
    if line:match "member%s+do" then
      in_member_block = true
      break
    elseif line:match "collection%s+do" then
      break
    elseif line:match "^%s*end%s*$" then
      break
    end
  end

  return in_member_block
end

---Find the controller action implementation for a given action
function RailsFramework._find_controller_action(resource_name, action_name)
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
      local def_start = line:find("def")
      return {
        file_path = actual_file,
        line_number = i,
        column = def_start or 1,
      }
    end
  end

  return nil
end

---Check if the current line is inside a collection block
function RailsFramework._is_in_collection_block(file_path, line_number)
  if vim.fn.filereadable(file_path) == 0 then
    return false
  end

  local content = vim.fn.readfile(file_path) or {}
  if #content == 0 then
    return false
  end
  local in_collection_block = false

  -- Search backwards from current line
  for i = line_number - 1, 1, -1 do
    local line = content[i]
    if line:match "collection%s+do" then
      in_collection_block = true
      break
    elseif line:match "member%s+do" then
      break
    elseif line:match "^%s*end%s*$" then
      break
    end
  end

  return in_collection_block
end

---Check if a method is in the private section of a Rails controller
function RailsFramework._is_private_method(file_path, line_number)
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

return RailsFramework
