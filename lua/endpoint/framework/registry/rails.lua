-- Rails framework implementation
local base = require "endpoint.framework.base"
local rails_config = require "endpoint.framework.config.rails"

-- Create a new Rails framework object inheriting from base
local M = base.new {}

function M:get_patterns(method)
  return rails_config.patterns[method:lower()] or {}
end

function M:get_file_types()
  -- Return the ripgrep file type for Ruby instead of file extension
  return { "ruby" }
end

function M:get_exclude_patterns()
  return rails_config.exclude_patterns
end

-- Extracts the endpoint path from Rails route or controller method
function M:extract_endpoint_path(content, method)
  -- Extract from route definitions like: get '/users', to: 'users#index'
  local path = content:match(method:lower() .. "%s+['\"]([^'\"]*)['\"]")
  if path then
    return path
  end

  -- Extract from resources
  local resource = content:match "resources%s+:(%w+)"
  if resource then
    local method_lower = method:lower()
    if method_lower == "get" then
      -- GET requests can be both collection (index) and member (show)
      -- Default to collection route for resources
      return "/" .. resource
    elseif method_lower == "post" then
      -- POST is typically for create (collection)
      return "/" .. resource
    elseif method_lower == "put" or method_lower == "patch" then
      -- PUT/PATCH are typically for update (member)
      return "/" .. resource .. "/:id"
    elseif method_lower == "delete" then
      -- DELETE is typically for destroy (member)
      return "/" .. resource .. "/:id"
    else
      return "/" .. resource
    end
  end

  -- Extract from documentation patterns like @api, @route, @method, or comments
  local doc_path = content:match("@api%s*{.*" .. method:lower() .. ".*}.-([/][^%s%}]*)")
  if doc_path then
    return doc_path
  end

  doc_path = content:match("@route.-" .. method:upper() .. ".-([/][^%s]*)")
  if doc_path then
    return doc_path
  end

  doc_path = content:match("@method.-" .. method:upper() .. ".-([/][^%s]*)")
  if doc_path then
    return doc_path
  end

  -- Extract from comment patterns like # GET /users
  doc_path = content:match("#%s*" .. method:upper() .. "%s+([/][^%s]*)")
  if doc_path then
    return doc_path
  end

  -- Extract from OAS Rails @summary patterns
  -- Look for patterns like @summary "Get a user by id" followed by method def
  if content:match("@summary.*" .. (method:lower():gsub("^%l", string.upper))) then
    -- This indicates a documented method, but we need to look at the method name
    local method_name = content:match "def%s+(%w+)"
    if method_name then
      -- Use the method name as endpoint for documented methods
      return "/" .. method_name
    end
  end

  -- Extract from controller methods
  local method_name = content:match "def%s+(%w+)"
  if method_name then
    if method_name == "index" then
      return ""
    elseif method_name == "show" then
      return "/:id"
    elseif method_name == "create" then
      return ""
    elseif method_name == "update" then
      return "/:id"
    elseif method_name == "destroy" then
      return "/:id"
    else
      return "/" .. method_name
    end
  end

  return ""
end

-- Combine base path with endpoint path
function M:combine_paths(base, endpoint)
  if not base or base == "" then
    if not endpoint or endpoint == "" then
      return "/"
    end
    if endpoint:sub(1, 1) ~= "/" then
      return "/" .. endpoint
    end
    return endpoint
  end

  if not endpoint or endpoint == "" then
    if base:sub(1, 1) ~= "/" then
      return "/" .. base
    end
    return base
  end

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

-- Extract base path from controller class name
function M:get_base_path(file_path, line_number)
  local lines = {}
  
  -- Try to read file safely
  local ok, result = pcall(function()
    if vim and vim.fn and vim.fn.readfile then
      return vim.fn.readfile(file_path)
    else
      local file_lines = {}
      for line in io.lines(file_path) do
        table.insert(file_lines, line)
      end
      return file_lines
    end
  end)
  
  if not ok or not result then
    return ""
  end
  
  lines = result
  
  -- Look for controller class name
  for _, line in ipairs(lines) do
    local class_match = line:match "class%s+(%w+)Controller"
    if class_match then
      -- Convert to snake_case path
      local controller_path = class_match:gsub("(%u)", function(c)
        return "_" .. c:lower()
      end):gsub("^_", "")
      
      return "/" .. controller_path:lower()
    end
  end

  return ""
end

-- Generate grep command for Rails
function M:get_grep_cmd(method, config)
  local patterns = self:get_patterns(method)
  if not patterns or #patterns == 0 then
    error("No patterns defined for method: " .. method)
  end

  local file_types = self:get_file_types()
  local exclude_patterns = self:get_exclude_patterns()

  local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"

  for _, file_type in ipairs(file_types) do
    cmd = cmd .. " --type " .. file_type
  end

  for _, pattern in ipairs(exclude_patterns) do
    cmd = cmd .. " --glob '!" .. pattern .. "'"
  end

  if config and config.rg_additional_args and config.rg_additional_args ~= "" then
    cmd = cmd .. " " .. config.rg_additional_args
  end

  -- Use multiple -e flags for each pattern to support Rails multi-pattern detection
  for _, pattern in ipairs(patterns) do
    cmd = cmd .. " -e '" .. pattern .. "'"
  end

  return cmd
end

-- Parse ripgrep output line
function M:parse_line(line, method)
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

return M