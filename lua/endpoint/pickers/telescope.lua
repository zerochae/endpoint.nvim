---@class endpoint.TelescopePicker
-- Telescope Picker Implementation (Function-based)
local M = {}

-- Check if Telescope is available
function M.is_available()
  return pcall(require, "telescope")
end

-- Show endpoints in Telescope picker
function M.show(endpoints, opts)
  if not M.is_available() then
    vim.notify("Telescope is not available", vim.log.levels.ERROR)
    return
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local themes = require "endpoint.ui.themes"
  local config_module = require "endpoint.config"

  opts = opts or {}
  local config = config_module.get()

  pickers
    .new(opts, {
      prompt_title = "Endpoints",
      finder = finders.new_table {
        results = endpoints,
        entry_maker = function(entry)
          -- Create display with method colors and icons
          local method_icon = themes.get_method_icon(entry.method, config)
          local method_text = themes.get_method_text(entry.method, config)
          local method_color = themes.get_method_color(entry.method, config)

          -- Use display_value if available (for Rails action annotations), otherwise use default format
          local endpoint_display = entry.display_value or (entry.method .. " " .. entry.endpoint_path)
          local display_text = string.format("%s %s", method_icon, endpoint_display)

          -- Calculate highlight length for Rails action annotations
          local highlight_length
          if entry.action and entry.display_value and entry.display_value:match("%[#.-%]") then
            -- Rails action annotation: highlight the entire "GET[#action]" part
            local method_with_action = entry.display_value:match("^([^%s]+)")
            if method_with_action then
              highlight_length = #method_icon + #method_with_action + 1
            else
              highlight_length = #method_icon + #method_text + 1
            end
          else
            -- Default: just highlight the method
            highlight_length = #method_icon + #method_text + 1
          end

          return {
            value = entry,
            display = function(_)
              return display_text, { { { 0, highlight_length }, method_color } }
            end,
            -- Include action name in search ordinal for Rails action annotations
            ordinal = entry.endpoint_path .. " " .. entry.method .. (entry.action and (" " .. entry.action) or ""),
            filename = entry.file_path,
            lnum = entry.line_number,
            col = entry.column,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      previewer = M.create_endpoint_previewer(),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            local endpoint = selection.value
            vim.cmd("edit " .. endpoint.file_path)
            vim.api.nvim_win_set_cursor(0, { endpoint.line_number, endpoint.column - 1 })
            -- Center the line in the window
            vim.cmd "normal! zz"
          end
        end)
        return true
      end,
    })
    :find()
end

-- Create endpoint-specific previewer with line/column highlighting
function M.create_endpoint_previewer()
  local previewers = require "telescope.previewers"
  local conf = require("telescope.config").values

  -- Track highlight namespaces for cleanup
  local highlight_ns = vim.api.nvim_create_namespace "endpoint_preview_highlight"

  return previewers.new_buffer_previewer {
    title = "Endpoint Preview",
    get_buffer_by_name = function(_, entry)
      return entry.filename
    end,
    define_preview = function(self, entry, _)
      local endpoint = entry.value
      if not endpoint or not endpoint.file_path then
        return
      end

      -- Read file content
      conf.buffer_previewer_maker(endpoint.file_path, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
        callback = function(bufnr)
          -- Clear previous highlights first
          vim.api.nvim_buf_clear_namespace(bufnr, highlight_ns, 0, -1)

          -- Highlight the endpoint line
          if endpoint.line_number then
            vim.api.nvim_buf_add_highlight(
              bufnr,
              highlight_ns,
              "TelescopePreviewMatch",
              endpoint.line_number - 1,
              math.max(0, (endpoint.column or 1) - 1),
              -1
            )
          end

          -- Set cursor to the endpoint line and center it
          if self.state.winid and vim.api.nvim_win_is_valid(self.state.winid) then
            local target_line = endpoint.line_number or 1
            local target_col = math.max(0, (endpoint.column or 1) - 1)

            vim.api.nvim_win_set_cursor(self.state.winid, { target_line, target_col })

            -- Center the line in the window
            vim.defer_fn(function()
              if vim.api.nvim_win_is_valid(self.state.winid) then
                vim.api.nvim_win_call(self.state.winid, function()
                  vim.cmd "normal! zz"
                end)
              end
            end, 10)
          end
        end,
      })
    end,
  }
end

return M
