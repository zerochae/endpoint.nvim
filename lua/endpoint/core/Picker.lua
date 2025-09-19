---@class endpoint.Picker
local Picker = {}
Picker.__index = Picker

function Picker:new(name)
  local picker = setmetatable({}, self)
  picker.name = name or "base"
  return picker
end

function Picker:is_available()
  error "is_available() must be implemented by subclass"
end

function Picker:show()
  error "show() must be implemented by subclass"
end

function Picker:get_name()
  return self.name
end

function Picker:_validate_endpoints(endpoints)
  if not endpoints or type(endpoints) ~= "table" then
    vim.notify("Invalid endpoints provided", vim.log.levels.ERROR)
    return false
  end

  if #endpoints == 0 then
    vim.notify("No endpoints found", vim.log.levels.INFO)
    return false
  end

  return true
end

function Picker:_format_endpoint_display(endpoint)
  return endpoint.display_value or (endpoint.method .. " " .. endpoint.endpoint_path)
end

function Picker:_navigate_to_endpoint(endpoint)
  if not endpoint.file_path then
    vim.notify("No file path for endpoint", vim.log.levels.ERROR)
    return
  end

  -- For React Router with component, navigate to component file
  if endpoint.component_file_path and vim.fn.filereadable(endpoint.component_file_path) == 1 then
    vim.cmd("edit " .. endpoint.component_file_path)
    -- Go to the component definition (typically first line or export line)
    vim.cmd "normal! gg"
    -- Try to find component definition
    local component_name = endpoint.component_name
    if component_name then
      vim.fn.search("\\(const\\|function\\|export default\\).*" .. component_name, "w")
    end
  else
    -- Default behavior: navigate to route definition
    vim.cmd("edit " .. endpoint.file_path)
    vim.api.nvim_win_set_cursor(0, { endpoint.line_number or 1, (endpoint.column or 1) - 1 })
  end

  -- Center the line in the window
  vim.cmd "normal! zz"
end

return Picker
