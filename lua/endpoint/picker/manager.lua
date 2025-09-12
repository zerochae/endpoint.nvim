local base_manager = require "endpoint.core.base_manager"
local detector = require "endpoint.services.detector"
local log = require "endpoint.utils.log"

local M = base_manager.create_manager("picker", "vim_ui_select")

-- Picker implementations will be registered during setup
-- Temporary fallback: register immediately for compatibility
M.register("telescope", "endpoint.picker.registry.telescope")
M.register("vim_ui_select", "endpoint.picker.registry.vim_ui_select")
M.register("snacks", "endpoint.picker.registry.snacks")

-- Current picker state
local current_picker = nil

-- Override get method to handle picker availability
local base_get = M.get
function M.get(picker_type)
  local picker = base_get(picker_type)

  -- Check if picker is available
  if picker and not picker:is_available() then
    log.warn("Picker " .. picker_type .. " is not available")
    return nil
  end

  return picker
end

function M.initialize(config)
  local requested_picker = config.picker or "vim_ui_select"
  local actual_picker = detector.resolve_picker(requested_picker)

  if actual_picker ~= requested_picker then
    log.warn(string.format("Picker '%s' not available, falling back to '%s'", requested_picker, actual_picker))
  end

  local picker = M.get(actual_picker)
  if not picker then
    log.error("Failed to create picker: " .. actual_picker)
    return false
  end

  current_picker = picker
  log.info("Initialized picker: " .. actual_picker)

  return true
end

function M.get_current_picker()
  return current_picker
end

function M.show_picker(method, opts)
  if not current_picker then
    log.error "Picker not initialized. Call setup() first."
    return false
  end

  opts = opts or {}

  local picker_opts = M.prepare_picker_data(method, opts)

  return current_picker:create_picker(picker_opts)
end

function M.prepare_picker_data(method, opts)
  local scanner = require "endpoint.services.scanner"

  if method == "ALL" then
    scanner.prepare_preview "ALL"
  else
    scanner.scan(method)
  end

  local cache_data = scanner.get_cache_data()
  local finder_table = cache_data.find_table
  local preview_table = cache_data.preview_table
  local items = {}

  if method == "ALL" then
    for _, mapping_object in pairs(finder_table) do
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
    for _, mapping_object in pairs(finder_table) do
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
  local seen = {}
  local unique_items = {}
  for _, item in ipairs(items) do
    if not seen[item.value] then
      seen[item.value] = true
      table.insert(unique_items, item)
    end
  end
  items = unique_items

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

function M.format_endpoint_display(method, path)
  local endpoint = require "endpoint.core"
  local config = endpoint.get_config()
  local themes = require "endpoint.ui.themes"

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

function M.get_preview_content(item, preview_table)
  local endpoint = item.value
  local preview_data = preview_table[endpoint]

  if not preview_data then
    return "Preview not available"
  end

  local file_path = preview_data.path
  local line_number = preview_data.line_number

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

function M.handle_selection(item, preview_table)
  local endpoint = item.value
  local preview_data = preview_table[endpoint]

  if not preview_data then
    log.error("Preview data not found for: " .. endpoint)
    return
  end

  local file_path = preview_data.path
  local line_number = preview_data.line_number
  local column = preview_data.column

  vim.cmd("edit " .. file_path)
  local bufnr = vim.fn.bufnr()
  vim.api.nvim_set_current_buf(bufnr)

  vim.schedule(function()
    local lnum = line_number or 1
    pcall(vim.api.nvim_win_set_cursor, 0, { lnum, (column or 1) - 1 })
    vim.cmd "norm! zz"
  end)
end

return M

