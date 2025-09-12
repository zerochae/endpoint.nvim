-- Snacks picker adapter
local base = require "endpoint.picker.base"

---@class PickerRegistrySnacks : endpoint.PickerRegistry
local M = base.new({}, "snacks")

function M:is_available()
  local ok, snacks = pcall(require, "snacks")
  return ok and snacks.picker ~= nil
end

function M:create_picker(opts)
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.picker then
    return false
  end

  -- Transform items for snacks format
  local snacks_items = {}
  for _, item in ipairs(opts.items) do
    table.insert(snacks_items, {
      text = opts.format_item and opts.format_item(item) or item.display_text or item.value,
      item = item,
    })
  end

  -- Create snacks picker options
  local snacks_opts = vim.tbl_deep_extend("force", {
    prompt = opts.prompt_title or "Endpoint Finder",
    format = function(item)
      return item.text
    end,
    preview = opts.preview_item and function(item)
      return {
        text = opts.preview_item(item.item),
        ft = self:get_filetype_for_item(item.item),
      }
    end or nil,
  }, opts.picker_opts or {})

  -- Show snacks picker
  snacks.picker.pick(snacks_items, snacks_opts):next(function(selected)
    if selected and opts.on_select then
      opts.on_select(selected.item)
    end
  end)

  return true
end

function M:get_filetype_for_item(item)
  -- Try to determine filetype from the endpoint data
  local scanner = require "endpoint.services.scanner"
  local preview_table = scanner.get_cache_data().preview_table
  local preview_data = preview_table[item.value]

  if preview_data and preview_data.path then
    return vim.filetype.match { filename = preview_data.path } or "text"
  end

  return "text"
end

return M
