local Picker = require "endpoint.core.Picker"
local Highlighter = require "endpoint.core.Highlighter"
local Themes = require "endpoint.core.Themes"
local class = require "endpoint.lib.middleclass"

---@class endpoint.VimUiSelectPicker
local VimUiSelectPicker = class('VimUiSelectPicker', Picker)

---Creates a new VimUiSelectPicker instance
function VimUiSelectPicker:initialize()
  Picker.initialize(self, {
    name = "vim_ui_select",
    themes = Themes:new(),
    highlighter = Highlighter:new "endpoint_vim_ui_select_highlight",
    has_dressing = pcall(require, "dressing"),
  })

  if self.has_dressing then
    self:_register_dressing_custom_kind()
  end
end

---Check if vim.ui.select is available (always true - built into Neovim)
function VimUiSelectPicker:is_available()
  return true
end

---Show endpoints in vim.ui.select
function VimUiSelectPicker:show(endpoints, opts)
  if not self:_validate_endpoints(endpoints) then
    return
  end

  opts = opts or {}

  -- Get picker-specific options
  local config_module = require "endpoint.config"
  local config = config_module.get()
  local vim_ui_opts = config.picker.options and config.picker.options.vim_ui_select or {}

  -- Merge with runtime opts (runtime opts take precedence)
  local merged_opts = vim.tbl_deep_extend("force", vim_ui_opts, opts)

  -- Check if filtering is enabled and needed
  local enable_filter = merged_opts.enable_filter == true -- default false
  local threshold = merged_opts.filter_threshold or 20

  if enable_filter and #endpoints > threshold then
    self:_show_with_filter(endpoints, merged_opts)
  else
    self:_show_direct(endpoints, merged_opts)
  end
end

---Create vim.ui.select configuration
function VimUiSelectPicker:_create_select_config(opts)
  local config_module = require "endpoint.config"
  local config = config_module.get()

  -- Get default prompt from config or fallback
  local default_prompt = "Endpoint: "
  if
    config.picker
    and config.picker.options
    and config.picker.options.vim_ui_select
    and config.picker.options.vim_ui_select.prompt
  then
    default_prompt = config.picker.options.vim_ui_select.prompt
  end

  local default_config = {
    prompt = default_prompt,
    format_item = function(item)
      -- Use themed format if icons are enabled (works with dressing + telescope backend)
      if config.ui and config.ui.show_icons ~= false then
        return self:_format_endpoint_with_theme(item, config)
      else
        return self:_format_endpoint_display(item)
      end
    end,
  }

  -- If dressing.nvim is available, add more customization
  if self.has_dressing then
    default_config.kind = "endpoint_select" -- Custom kind for dressing.nvim theming
    -- The custom_kind will be handled by dressing.nvim's telescope backend
  end

  -- Merge user opts with defaults (user options override defaults)
  return vim.tbl_deep_extend("force", default_config, opts)
end

---Show endpoints directly without filtering
function VimUiSelectPicker:_show_direct(endpoints, opts)
  local config = self:_create_select_config(opts)

  vim.ui.select(endpoints, config, function(choice)
    if choice then
      self:_navigate_to_endpoint(choice)
    end
  end)
end

---Show endpoints with filtering for large lists
function VimUiSelectPicker:_show_with_filter(endpoints, opts)
  local filter_prompt = opts.filter_prompt or "Filter endpoints (method/path): "

  local input_opts = {
    prompt = filter_prompt,
    default = "",
  }

  -- Add some common filter examples as hint
  if opts.show_filter_examples ~= false then
    input_opts.prompt = filter_prompt .. "(e.g. GET, /api, users) "
  end

  -- Add method highlighting function for dressing.nvim input backends
  if self.has_dressing then
    input_opts.highlight = self:_create_method_highlight_function()
  end

  vim.ui.input(input_opts, function(filter_text)
    if not filter_text or filter_text == "" then
      -- No filter provided, show first 20 items
      local limited_endpoints = vim.list_slice(endpoints, 1, 20)
      vim.notify(
        string.format("Showing first 20 of %d endpoints (no filter provided)", #endpoints),
        vim.log.levels.INFO
      )
      self:_show_direct(limited_endpoints, opts)
      return
    end

    -- Filter endpoints based on user input
    local filtered_endpoints = self:_filter_endpoints(endpoints, filter_text)

    if #filtered_endpoints == 0 then
      vim.notify("No endpoints match filter: " .. filter_text, vim.log.levels.WARN)
      return
    end

    if #filtered_endpoints > 20 then
      vim.notify(
        string.format("Filter matched %d endpoints, showing first 20", #filtered_endpoints),
        vim.log.levels.INFO
      )
      filtered_endpoints = vim.list_slice(filtered_endpoints, 1, 20)
    end

    self:_show_direct(filtered_endpoints, opts)
  end)
end

---Filter endpoints based on user input
function VimUiSelectPicker:_filter_endpoints(endpoints, filter_text)
  filter_text = filter_text:lower()
  local filtered = {}

  for _, endpoint in ipairs(endpoints) do
    local method = endpoint.method:lower()
    local path = endpoint.endpoint_path:lower()
    local file = endpoint.file_path and endpoint.file_path:lower() or ""

    -- Match against method, path, or file path
    if method:find(filter_text, 1, true) or path:find(filter_text, 1, true) or file:find(filter_text, 1, true) then
      table.insert(filtered, endpoint)
    end
  end

  return filtered
end

---Create telescope entry for dressing.nvim telescope backend
function VimUiSelectPicker:_create_telescope_entry(item, config)
  -- Use the same entry creation logic as the telescope picker for consistency
  local display_text = self:_format_endpoint_with_theme(item, config)

  -- Get theme data for telescope-specific highlighting
  local method_icon = self.themes:get_method_icon(item.method, config)
  local method_text = self.themes:get_method_text(item.method, config)
  local method_color = self.themes:get_method_color(item.method, config)

  -- Calculate highlight length for method highlighting
  local highlight_length = self.highlighter:calculate_highlight_length(item, method_icon, method_text)

  return {
    value = item,
    display = function(_)
      return display_text, { { { 0, highlight_length }, method_color } }
    end,
    -- Include action name and controller name in search ordinal for Rails action annotations
    ordinal = item.endpoint_path
      .. " "
      .. item.method
      .. (item.action and (" " .. item.action) or "")
      .. (item.controller and (" " .. item.controller) or "")
      .. (item.display_value and (" " .. item.display_value) or ""),
    filename = item.file_path,
    lnum = item.line_number,
    col = item.column,
    end_lnum = item.end_line_number, -- For multiline highlighting
  }
end

---Create method highlighting function for vim.ui.input (used for filtering)
---This provides method highlighting in dressing.nvim input backends
function VimUiSelectPicker:_create_method_highlight_function()
  return function(input_text)
    local highlights = {}
    local config_module = require "endpoint.config"
    local config = config_module.get()

    -- Simple pattern matching for HTTP methods
    local methods = { "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS" }

    for _, method in ipairs(methods) do
      local method_color = self.themes:get_method_color(method, config)
      local start_pos = input_text:upper():find(method:upper())

      if start_pos then
        table.insert(highlights, {
          start_pos - 1, -- Convert to 0-based indexing
          start_pos - 1 + #method,
          method_color,
        })
      end
    end

    return highlights
  end
end

---Register custom_kind with dressing.nvim for method highlighting
function VimUiSelectPicker:_register_dressing_custom_kind()
  local ok, dressing_select_telescope = pcall(require, "dressing.select.telescope")
  if not ok then
    return
  end

  -- Check if custom_kind table exists and extend it
  if dressing_select_telescope.custom_kind then
    dressing_select_telescope.custom_kind.endpoint_select = function(opts, defaults, items)
      local entry_display_ok = pcall(require, "telescope.pickers.entry_display")
      local finders_ok, finders = pcall(require, "telescope.finders")

      if not entry_display_ok or not finders_ok then
        -- Fallback: telescope not available, skip custom kind
        return
      end

      local entries = {}
      local text_width = 1

      for idx, item in ipairs(items) do
        local text = opts.format_item(item)
        text_width = math.max(text_width, vim.api.nvim_strwidth(text))

        -- Create entry with method highlighting
        local config_module = require "endpoint.config"
        local config = config_module.get()

        -- Get theme data for method highlighting
        local method_icon = self.themes:get_method_icon(item.method, config)
        local method_text = self.themes:get_method_text(item.method, config)
        local method_color = self.themes:get_method_color(item.method, config)

        -- Calculate highlight length
        local highlight_length = self.highlighter:calculate_highlight_length(item, method_icon, method_text)

        table.insert(entries, {
          idx = idx,
          display = function(_)
            return text, { { { 0, highlight_length }, method_color } }
          end,
          value = item,
          ordinal = item.endpoint_path
            .. " "
            .. item.method
            .. (item.action and (" " .. item.action) or "")
            .. (item.controller and (" " .. item.controller) or "")
            .. (item.display_value and (" " .. item.display_value) or ""),
        })
      end

      defaults.finder = finders.new_table {
        results = entries,
        entry_maker = function(item)
          return item
        end,
      }

      -- Apply prompt from opts to defaults if provided
      if opts.prompt then
        defaults.prompt_title = opts.prompt
      end
    end
  end
end

return VimUiSelectPicker
