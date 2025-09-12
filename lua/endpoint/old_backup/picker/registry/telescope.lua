local base = require "endpoint.picker.base"

---@class PickerRegistryTelescope : endpoint.PickerRegistry
local M = {}

function M:is_available()
  local ok, _ = pcall(require, "telescope.pickers")
  return ok
end

function M:create_picker(opts)
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    return false
  end

  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local entry_display = require "telescope.pickers.entry_display"

  -- Create custom entry maker for telescope
  local entry_maker = function(item)
    local state = require "endpoint.core.state"
    local config = state.get_config()
    local themes = require "endpoint.ui.themes"

    local method = item.method
    local path = item.path

    local icon = themes.get_method_icon(method, config)
    local method_text = themes.get_method_text(method, config)
    local method_color = themes.get_method_color(method, config)

    -- Create display configuration
    local display_parts = {}
    if icon ~= "" then
      table.insert(display_parts, { width = 2 })
    end
    if method_text ~= "" then
      table.insert(display_parts, { width = string.len(method_text) })
    end
    table.insert(display_parts, { remaining = true })

    local displayer = entry_display.create {
      separator = " ",
      items = display_parts,
    }

    return {
      value = item.value,
      display = function()
        local display_items = {}

        if icon ~= "" then
          table.insert(display_items, icon)
        end
        if method_text ~= "" then
          table.insert(display_items, { method_text, method_color })
        end
        table.insert(display_items, path)

        return displayer(display_items)
      end,
      ordinal = item.value,
      item = item,
    }
  end

  -- Create telescope picker
  local picker = pickers.new(opts.picker_opts or {}, {
    prompt_title = opts.prompt_title or "Endpoint Finder",
    finder = finders.new_table {
      results = opts.items,
      entry_maker = entry_maker,
    },
    sorter = conf.generic_sorter(opts.picker_opts or {}),
    previewer = self:create_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        if entry and opts.on_select then
          opts.on_select(entry.item)
        end
      end)
      return true
    end,
  })

  picker:find()
  return true
end

function M:create_previewer(opts)
  local previewers = require "telescope.previewers"
  local conf = require("telescope.config").values
  local scanner = require "endpoint.services.scanner"

  return previewers.new_buffer_previewer {
    title = opts.preview_title or "Preview",
    define_preview = function(self, entry)
      -- Simple approach: only create preview table if needed
      local preview_table = scanner.get_cache_data().preview_table
      if not preview_table or not next(preview_table) then
        -- Determine method from entry data
        local method = entry.item.method or "GET"
        scanner.prepare_preview(method)
        preview_table = scanner.get_cache_data().preview_table
      end

      local endpoint = entry.value
      if not preview_table[endpoint] then
        -- Try to create preview data for this specific endpoint
        local method_part, path_part = endpoint:match "^(%S+)%s+(.+)$"
        if method_part then
          scanner.prepare_preview(method_part)
          preview_table = scanner.get_cache_data().preview_table
        end

        if not preview_table[endpoint] then
          vim.notify("Preview data not found for: " .. tostring(endpoint), vim.log.levels.WARN)
          return
        end
      end

      local path = preview_table[endpoint].path
      local line_number = preview_table[endpoint].line_number
      local column = preview_table[endpoint].column
      entry.path = path
      entry.lnum = line_number
      entry.col = column
      local bufnr = self.state.bufnr

      conf.buffer_previewer_maker(path, bufnr, {
        callback = function()
          vim.schedule(function()
            -- Set cursor on entry
            local lnum = entry.lnum or 1
            pcall(vim.api.nvim_win_set_cursor, self.state.winid, { lnum, 0 })
            vim.api.nvim_buf_call(bufnr, function()
              vim.cmd "norm! zz"
            end)

            -- Add highlighting for the annotation line
            local ns_id = vim.api.nvim_create_namespace "endpoint_annotation_highlight"
            vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

            if entry.lnum then
              vim.api.nvim_buf_add_highlight(
                bufnr,
                ns_id,
                "TelescopePreviewMatch", -- Use Telescope's match highlight
                entry.lnum - 1, -- 0-indexed
                0,
                -1
              )
            end
          end)
        end,
      })
    end,
  }
end

return base.new(M, "telescope")
