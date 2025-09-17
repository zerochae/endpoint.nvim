local Picker = require "endpoint.core.Picker"

---@class TelescopePicker : Picker
local TelescopePicker = setmetatable({}, { __index = Picker })
TelescopePicker.__index = TelescopePicker

---Creates a new TelescopePicker instance
---@return TelescopePicker
function TelescopePicker:new()
  local telescope_picker = setmetatable({}, self)
  telescope_picker.name = "telescope"
  telescope_picker.telescope_available = pcall(require, "telescope")
  telescope_picker.highlight_ns = vim.api.nvim_create_namespace "endpoint_preview_highlight"
  return telescope_picker
end

---Check if Telescope is available
---@return boolean
function TelescopePicker:is_available()
  return self.telescope_available
end

---Show endpoints in Telescope picker
---@param endpoints endpoint.entry[]
---@param opts? table
function TelescopePicker:show(endpoints, opts)
  if not self:is_available() then
    vim.notify("Telescope is not available", vim.log.levels.ERROR)
    return
  end

  if not self:_validate_endpoints(endpoints) then
    return
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local config_module = require "endpoint.config"

  opts = opts or {}
  local config = config_module.get()

  pickers
    .new(opts, {
      prompt_title = "Endpoints",
      finder = finders.new_table {
        results = endpoints,
        entry_maker = function(entry)
          return self:_create_entry(entry, config)
        end,
      },
      sorter = conf.generic_sorter(opts),
      previewer = self:_create_previewer(),
      attach_mappings = function(prompt_bufnr)
        return self:_attach_mappings(prompt_bufnr, actions, action_state)
      end,
    })
    :find()
end

---Create telescope entry for an endpoint
---@param entry endpoint.entry
---@param config table
---@return table
function TelescopePicker:_create_entry(entry, config)
  local themes = require "endpoint.ui.themes"

  -- Create display with method colors and icons
  local method_icon = themes.get_method_icon(entry.method, config)
  local method_text = themes.get_method_text(entry.method, config)
  local method_color = themes.get_method_color(entry.method, config)

  -- Use display_value if available (for Rails action annotations), otherwise use default format
  local endpoint_display = self:_format_endpoint_display(entry)
  local display_text = string.format("%s %s", method_icon, endpoint_display)

  -- Calculate highlight length for Rails controller#action annotations
  local highlight_length = self:_calculate_highlight_length(entry, method_icon, method_text)

  return {
    value = entry,
    display = function(_)
      return display_text, { { { 0, highlight_length }, method_color } }
    end,
    -- Include action name and controller name in search ordinal for Rails action annotations
    ordinal = entry.endpoint_path
      .. " "
      .. entry.method
      .. (entry.action and (" " .. entry.action) or "")
      .. (entry.controller and (" " .. entry.controller) or "")
      .. (entry.display_value and (" " .. entry.display_value) or ""),
    filename = entry.file_path,
    lnum = entry.line_number,
    col = entry.column,
  }
end

---Calculate highlight length for different display formats
---@param entry endpoint.entry
---@param method_icon string
---@param method_text string
---@return integer
function TelescopePicker:_calculate_highlight_length(entry, method_icon, method_text)
  if entry.display_value and entry.display_value:match "%[.+#.+%]" then
    -- Rails controller#action annotation: highlight the entire "GET[controller#action]" part
    local method_with_action = entry.display_value:match "^([^%s]+)"
    if method_with_action then
      return #method_icon + #method_with_action + 1
    else
      return #method_icon + #method_text + 1
    end
  elseif entry.action and entry.display_value and entry.display_value:match "%[#.-%]" then
    -- Legacy Rails action annotation: highlight the entire "GET[#action]" part
    local method_with_action = entry.display_value:match "^([^%s]+)"
    if method_with_action then
      return #method_icon + #method_with_action + 1
    else
      return #method_icon + #method_text + 1
    end
  else
    -- Default: just highlight the method
    return #method_icon + #method_text + 1
  end
end

---Create endpoint-specific previewer with line/column highlighting
---@return table
function TelescopePicker:_create_previewer()
  local previewers = require "telescope.previewers"
  local conf = require("telescope.config").values

  return previewers.new_buffer_previewer {
    title = "Endpoint Preview",
    get_buffer_by_name = function(_, entry)
      return entry.filename
    end,
    define_preview = function(picker_self, entry, _)
      self:_define_preview(picker_self, entry, conf)
    end,
  }
end

---Define preview behavior for the previewer
---@param picker_self table
---@param entry table
---@param conf table
function TelescopePicker:_define_preview(picker_self, entry, conf)
  local endpoint = entry.value
  if not endpoint or not endpoint.file_path then
    return
  end

  -- Determine preview file and position
  local preview_file, preview_line, preview_col = self:_get_preview_location(endpoint)

  -- Read file content
  conf.buffer_previewer_maker(preview_file, picker_self.state.bufnr, {
    bufname = picker_self.state.bufname,
    winid = picker_self.state.winid,
    callback = function(bufnr)
      self:_handle_preview_callback(bufnr, endpoint, picker_self, preview_line, preview_col)
    end,
  })
end

---Get preview file location (handles React Router component files)
---@param endpoint endpoint.entry
---@return string?, integer?, integer?
function TelescopePicker:_get_preview_location(endpoint)
  local preview_file = endpoint.file_path
  local preview_line = endpoint.line_number
  local preview_col = endpoint.column

  -- For React Router with component, preview component file instead of route definition
  if endpoint.component_file_path and vim.fn.filereadable(endpoint.component_file_path) == 1 then
    preview_file = endpoint.component_file_path
    preview_line = 1 -- Start at the top of component file
    preview_col = 1
  end

  return preview_file, preview_line, preview_col
end

---Handle preview callback for highlighting and cursor positioning
---@param bufnr integer
---@param endpoint endpoint.entry
---@param picker_self table
---@param preview_line integer?
---@param preview_col integer?
function TelescopePicker:_handle_preview_callback(bufnr, endpoint, picker_self, preview_line, preview_col)
  -- Clear previous highlights first
  vim.api.nvim_buf_clear_namespace(bufnr, self.highlight_ns, 0, -1)

  if endpoint.component_file_path and endpoint.component_name then
    self:_highlight_component_definition(bufnr, endpoint)
  else
    self:_highlight_endpoint_line(bufnr, preview_line, preview_col)
  end

  -- Set cursor and center
  self:_set_preview_cursor(picker_self, preview_line, preview_col)
end

---Highlight component definition in React Router components
---@param bufnr integer
---@param endpoint endpoint.entry
function TelescopePicker:_highlight_component_definition(bufnr, endpoint)
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      for line_idx, line in ipairs(lines) do
        -- Look for component definition patterns
        if
          line:match("const%s+" .. endpoint.component_name)
          or line:match("function%s+" .. endpoint.component_name)
          or line:match("export%s+default%s+" .. endpoint.component_name)
          or line:match("export%s+default%s+function%s+" .. endpoint.component_name)
        then
          vim.api.nvim_buf_add_highlight(bufnr, self.highlight_ns, "TelescopePreviewMatch", line_idx - 1, 0, -1)
          break
        end
      end
    end
  end, 50)
end

---Highlight the endpoint line
---@param bufnr integer
---@param preview_line integer?
---@param preview_col integer?
function TelescopePicker:_highlight_endpoint_line(bufnr, preview_line, preview_col)
  if preview_line then
    vim.api.nvim_buf_add_highlight(
      bufnr,
      self.highlight_ns,
      "TelescopePreviewMatch",
      preview_line - 1,
      math.max(0, (preview_col or 1) - 1),
      -1
    )
  end
end

---Set cursor position and center in preview window
---@param picker_self table
---@param preview_line integer?
---@param preview_col integer?
function TelescopePicker:_set_preview_cursor(picker_self, preview_line, preview_col)
  if picker_self.state.winid and vim.api.nvim_win_is_valid(picker_self.state.winid) then
    local target_line = preview_line or 1
    local target_col = math.max(0, (preview_col or 1) - 1)

    vim.api.nvim_win_set_cursor(picker_self.state.winid, { target_line, target_col })

    -- Center the line in the window
    vim.defer_fn(function()
      if vim.api.nvim_win_is_valid(picker_self.state.winid) then
        vim.api.nvim_win_call(picker_self.state.winid, function()
          vim.cmd "normal! zz"
        end)
      end
    end, 10)
  end
end

---Attach key mappings for telescope picker
---@param prompt_bufnr integer
---@param actions table
---@param action_state table
---@return boolean
function TelescopePicker:_attach_mappings(prompt_bufnr, actions, action_state)
  actions.select_default:replace(function()
    actions.close(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    if selection then
      self:_navigate_to_endpoint(selection.value)
    end
  end)
  return true
end

-- Create and return singleton instance for backward compatibility
local telescope_picker = TelescopePicker:new()

---@class endpoint.pickers.telescope
local M = {}

---Check if Telescope is available
---@return boolean
function M.is_available()
  return telescope_picker:is_available()
end

---Show endpoints in Telescope picker
---@param endpoints endpoint.entry[]
---@param opts? table
function M.show(endpoints, opts)
  return telescope_picker:show(endpoints, opts)
end

---Create endpoint-specific previewer with line/column highlighting
---@return table
function M.create_endpoint_previewer()
  return telescope_picker:_create_previewer()
end

return M
