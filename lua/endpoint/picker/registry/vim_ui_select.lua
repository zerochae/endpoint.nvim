local base = require "endpoint.picker.base"

---@class PickerRegistryVimUISelect : endpoint.PickerRegistry
local M = base.new({}, "vim_ui_select")

function M:is_available()
  return vim.ui and vim.ui.select ~= nil
end

function M:create_picker(opts)
  if not vim.ui or not vim.ui.select then
    return false
  end

  local items = opts.items or {}
  local display_items = {}
  for _, item in ipairs(items) do
    local display_text = opts.format_item and opts.format_item(item) or item.display_text or item.value
    if item.method then
      local formatted_method = self:format_method_display(item.method)
      local path_only = display_text:gsub("^" .. item.method .. "%s+", "")
      display_text = formatted_method .. " " .. path_only
    end
    table.insert(display_items, display_text)
  end

  vim.ui.select(display_items, {
    prompt = (opts.prompt_title or "Endpoint Finder") .. ": ",
    format_item = function(item)
      return tostring(item)
    end,
    kind = "endpoint",
  }, function(choice, idx)
    if choice and idx and opts.on_select then
      local selected_item = items[idx]
      if selected_item then
        opts.on_select(selected_item)
      end
    end
  end)

  return true
end

function M:format_method_display(method)
  local state = require "endpoint.core.state"
  local config = state.get_config()
  local themes = require "endpoint.ui.themes"

  if not config then
    return method
  end

  local parts = {}

  if config.ui.show_icons then
    local icon = themes.get_method_icon(method, config)
    if icon and icon ~= "" then
      table.insert(parts, icon)
    end
  end

  if config.ui.show_method then
    table.insert(parts, method)
  end

  return table.concat(parts, " ")
end

return M
