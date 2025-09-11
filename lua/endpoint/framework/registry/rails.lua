-- Rails framework implementation - completely rewritten
local base = require "endpoint.framework.base"
local rails_config = require "endpoint.framework.config.rails"

-- Create a new Rails framework object inheriting from base
local M = base.new {}

function M:get_patterns(method)
  return rails_config.patterns[method:lower()] or {}
end

function M:get_file_types()
  return { "ruby" }
end

function M:get_exclude_patterns()
  return rails_config.exclude_patterns
end

function M:get_file_patterns()
  return rails_config.file_patterns
end

function M:can_handle(line)
  if not line or line == "" then
    return false
  end
  
  -- Check if line contains Rails controller method definitions
  local rails_methods = {"index", "show", "new", "edit", "create", "update", "destroy"}
  for _, method in ipairs(rails_methods) do
    if line:match("def%s+" .. method) then
      return true
    end
  end
  
  return false
end

-- Extract Rails method name from controller method definition
function M:extract_rails_method(content)
  local method = content:match("def%s+(%w+)")
  return method
end

-- Extract endpoint path from Rails controller method
function M:extract_endpoint_path(content, method)
  local rails_method = self:extract_rails_method(content)
  if not rails_method then
    return ""
  end

  -- Map Rails methods to endpoint paths
  if rails_method == "index" then
    return ""
  elseif rails_method == "show" then
    return "/:id"
  elseif rails_method == "new" then
    return "/new"
  elseif rails_method == "edit" then
    return "/:id/edit"
  elseif rails_method == "create" then
    return ""
  elseif rails_method == "update" then
    return "/:id"
  elseif rails_method == "destroy" then
    return "/:id"
  else
    -- Custom action
    return "/" .. rails_method
  end
end

-- Get display method text based on display_mode
function M:get_display_method(content, method)
  local rails_method = self:extract_rails_method(content)
  if not rails_method then
    return method:upper()
  end

  -- Get display_mode from core config, fallback to rails_config
  local core_config = require("endpoint.core").get_config()
  local display_mode = (core_config.frameworks_config and core_config.frameworks_config.rails and core_config.frameworks_config.rails.display_mode) or rails_config.display_mode or "native"
  
  
  if display_mode == "native" then
    return rails_method
  else -- restful
    local http_method = rails_config.rails_methods[rails_method]
    if type(http_method) == "table" then
      -- For update method which can be PUT or PATCH
      return table.concat(http_method, "/")
    elseif http_method then
      return http_method
    else
      return method:upper()
    end
  end
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

-- Generate grep command for Rails - simple controller method search only
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

  -- Use single pattern - only controller methods
  cmd = cmd .. " '" .. patterns[1] .. "'"
  return cmd
end

-- Parse ripgrep output line with Rails-specific display method
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
  
  -- Get Rails-specific display method
  local display_method = self:get_display_method(content, method)

  return {
    file_path = file_path,
    line_number = line_number,
    column = column,
    endpoint_path = full_path,
    method = display_method, -- This now shows Rails method or HTTP method based on config
    raw_line = line,
    content = content,
  }
end

return M