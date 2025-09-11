-- Picker Manager
-- Manages picker selection and provides a unified interface

local detector = require("endpoint.picker.detector")
local debug = require("endpoint.utils.debug")
local M = {}

local current_picker = nil

-- Factory function to create picker instances
-- @param picker_name string: Name of the picker to create
-- @return BasePicker|nil: Picker instance or nil if not found
local function create_picker(picker_name)
  local picker_module = string.format("endpoint.picker.registry.%s", picker_name)
  local ok, picker_instance = pcall(require, picker_module)
  
  if not ok then
    return nil
  end
  
  return picker_instance
end

-- Initialize picker based on config
-- @param config table: User configuration
-- @return boolean: true if picker was successfully initialized
function M.initialize(config)
  local requested_picker = config.picker or "vim_ui_select"
  local actual_picker = detector.resolve_picker(requested_picker)
  
  -- Warn if fallback occurred
  if actual_picker ~= requested_picker then
    debug.warn(string.format("Picker '%s' not available, falling back to '%s'", requested_picker, actual_picker))
  end
  
  local picker = create_picker(actual_picker)
  if not picker then
    vim.notify("Failed to create picker: " .. actual_picker, vim.log.levels.ERROR)
    return false
  end
  
  -- This should always succeed since resolve_picker ensures availability
  if not picker:is_available() then
    vim.notify("Picker not available: " .. actual_picker, vim.log.levels.ERROR)
    return false
  end
  
  current_picker = picker
  debug.info("Initialized picker: " .. actual_picker)
  
  return true
end

-- Get current picker instance
-- @return PickerInterface|nil: Current picker or nil if not initialized
function M.get_current_picker()
  return current_picker
end

-- Create and show picker with endpoint data
-- @param method string: HTTP method (GET, POST, PUT, DELETE, PATCH, ALL)
-- @param opts table: Additional options
-- @return boolean: true if picker was successfully created
function M.show_picker(method, opts)
  if not current_picker then
    vim.notify("Picker not initialized. Call setup() first.", vim.log.levels.ERROR)
    return false
  end
  
  opts = opts or {}
  
  -- Prepare picker data
  local picker_opts = M.prepare_picker_data(method, opts)
  
  return current_picker:create_picker(picker_opts)
end

-- Prepare data for picker
-- @param method string: HTTP method
-- @param opts table: Additional options
-- @return table: Prepared picker options
function M.prepare_picker_data(method, opts)
  local util = require("endpoint.services.util")
  local themes = require("endpoint.ui.themes")
  
  -- Get endpoint data
  if method == "ALL" then
    util.create_endpoint_preview_table("ALL")
  else
    util.create_endpoint_table(method)
  end
  
  local finder_table = util.get_find_table()
  local preview_table = util.get_preview_table()
  local items = {}
  
  -- Prepare items for picker
  if method == "ALL" then
    -- Handle all endpoints
    for file_path, mapping_object in pairs(finder_table) do
      for annotation, mappings in pairs(mapping_object) do
        for _, mapping_item in ipairs(mappings) do
          local endpoint_path = mapping_item.value or ""
          local endpoint = annotation .. " " .. endpoint_path
          table.insert(items, {
            value = endpoint,
            method = annotation,
            path = endpoint_path,
            display_text = M.format_endpoint_display(annotation, endpoint_path),
          })
        end
      end
    end
  else
    -- Handle specific method
    for file_path, mapping_object in pairs(finder_table) do
      for annotation, mappings in pairs(mapping_object) do
        if annotation == method then
          for _, mapping_item in ipairs(mappings) do
            local endpoint_path = mapping_item.value or ""
            local endpoint = method .. " " .. endpoint_path
            table.insert(items, {
              value = endpoint,
              method = method,
              path = endpoint_path,
              display_text = M.format_endpoint_display(method, endpoint_path),
            })
          end
        end
      end
    end
  end
  
  -- Remove duplicates
  items = util.check_duplicate_entries(items)
  
  return {
    prompt_title = opts.prompt_title or "Endpoint Finder",
    preview_title = opts.preview_title or "Preview",
    items = items,
    on_select = function(item)
      M.handle_selection(item, preview_table)
    end,
    format_item = function(item)
      return item.display_text
    end,
    preview_item = function(item)
      return M.get_preview_content(item, preview_table)
    end,
    picker_opts = opts.picker_opts or {},
  }
end

-- Format endpoint display text
-- @param method string: HTTP method
-- @param path string: Endpoint path
-- @return string: Formatted display text
function M.format_endpoint_display(method, path)
  local endpoint = require("endpoint.core")
  local config = endpoint.get_config()
  local themes = require("endpoint.ui.themes")
  
  local icon = themes.get_method_icon(method, config)
  local method_text = themes.get_method_text(method, config)
  
  local parts = {}
  if icon ~= "" then
    table.insert(parts, icon)
  end
  if method_text ~= "" then
    table.insert(parts, method_text)
  end
  table.insert(parts, path)
  
  return table.concat(parts, " ")
end

-- Get preview content for an item
-- @param item table: Selected item
-- @param preview_table table: Preview data table
-- @return string: Preview content
function M.get_preview_content(item, preview_table)
  local endpoint = item.value
  local preview_data = preview_table[endpoint]
  
  if not preview_data then
    return "Preview not available"
  end
  
  local file_path = preview_data.path
  local line_number = preview_data.line_number
  
  -- Read file content around the line
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return "Failed to read file: " .. file_path
  end
  
  local preview_lines = {}
  local start_line = math.max(1, line_number - 5)
  local end_line = math.min(#lines, line_number + 5)
  
  for i = start_line, end_line do
    local prefix = i == line_number and ">" or " "
    table.insert(preview_lines, string.format("%s %3d: %s", prefix, i, lines[i] or ""))
  end
  
  return table.concat(preview_lines, "\n")
end

-- Handle item selection
-- @param item table: Selected item
-- @param preview_table table: Preview data table
function M.handle_selection(item, preview_table)
  local endpoint = item.value
  local preview_data = preview_table[endpoint]
  
  if not preview_data then
    vim.notify("Preview data not found for: " .. endpoint, vim.log.levels.ERROR)
    return
  end
  
  local file_path = preview_data.path
  local line_number = preview_data.line_number
  local column = preview_data.column
  
  -- Open file and navigate to position
  vim.cmd("edit " .. file_path)
  local bufnr = vim.fn.bufnr()
  vim.api.nvim_set_current_buf(bufnr)
  
  vim.schedule(function()
    local util = require("endpoint.services.util")
    local cursor_entry = {
      path = file_path,
      lnum = line_number,
      col = column,
    }
    util.set_cursor_on_entry(cursor_entry, bufnr, 0)
  end)
end

return M