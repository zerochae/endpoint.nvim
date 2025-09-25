local Picker = require "endpoint.core.Picker"
local Highlighter = require "endpoint.core.Highlighter"

---@class endpoint.TelescopePicker
local TelescopePicker = Picker:new "telescope"
TelescopePicker.__index = TelescopePicker

---Creates a new TelescopePicker instance
function TelescopePicker:new()
  local telescope_picker = setmetatable({}, TelescopePicker)
  telescope_picker.telescope_available = pcall(require, "telescope")
  telescope_picker.highlighter = Highlighter:new "endpoint_preview_highlight"
  return telescope_picker
end

---Check if Telescope is available
function TelescopePicker:is_available()
  return self.telescope_available
end

---Show endpoints in Telescope picker
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
function TelescopePicker:_create_entry(entry, config)
  -- Use common theme formatting from base Picker
  local display_text = self:_format_endpoint_with_theme(entry, config)

  -- Get theme data for telescope-specific highlighting
  local method_icon = self.themes:get_method_icon(entry.method, config)
  local method_text = self.themes:get_method_text(entry.method, config)
  local method_color = self.themes:get_method_color(entry.method, config)

  -- Calculate highlight length for Rails controller#action annotations
  local highlight_length = self.highlighter:calculate_highlight_length(entry, method_icon, method_text)

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
    end_lnum = entry.end_line_number, -- For multiline highlighting
  }
end

---Create endpoint-specific previewer with line/column highlighting
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
function TelescopePicker:_handle_preview_callback(bufnr, endpoint, picker_self, preview_line, preview_col)
  local config_module = require "endpoint.config"
  local config = config_module.get()

  -- Clear previous highlights first
  self.highlighter:clear_highlights(bufnr)

  -- Only apply highlighting if enabled in config
  if self.highlighter:is_highlighting_enabled(config) then
    if endpoint.component_file_path and endpoint.component_name then
      self.highlighter:highlight_component_definition(bufnr, endpoint)
    else
      self.highlighter:highlight_endpoint(bufnr, endpoint)
    end
  end

  -- Set cursor and center (always enabled)
  self:_set_preview_cursor(picker_self, preview_line, preview_col)
end

---Set cursor position and center in preview window
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

return TelescopePicker
