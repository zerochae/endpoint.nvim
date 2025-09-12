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
  
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local themes = require("endpoint.ui.themes")
  local config_module = require("endpoint.config")
  
  opts = opts or {}
  local config = config_module.get()
  
  pickers.new(opts, {
    prompt_title = "Endpoints",
    finder = finders.new_table({
      results = endpoints,
      entry_maker = function(entry)
        -- Create display with method colors and icons
        local method_icon = themes.get_method_icon(entry.method, config)
        local method_text = themes.get_method_text(entry.method, config)
        local method_color = themes.get_method_color(entry.method, config)
        
        local display_text = string.format("%s %s %s", 
          method_icon, method_text, entry.endpoint_path)
        
        return {
          value = entry,
          display = function(entry_display)
            return display_text, { { { 0, #method_icon + #method_text + 1 }, method_color } }
          end,
          ordinal = entry.endpoint_path .. " " .. entry.method,
          filename = entry.file_path,
          lnum = entry.line_number,
          col = entry.column,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = M.create_endpoint_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local endpoint = selection.value
          vim.cmd("edit " .. endpoint.file_path)
          vim.api.nvim_win_set_cursor(0, { endpoint.line_number, endpoint.column - 1 })
        end
      end)
      return true
    end,
  }):find()
end

-- Create endpoint-specific previewer with line/column highlighting
function M.create_endpoint_previewer(opts)
  local previewers = require("telescope.previewers")
  local conf = require("telescope.config").values
  
  return previewers.new_buffer_previewer({
    title = "Endpoint Preview",
    get_buffer_by_name = function(_, entry)
      return entry.filename
    end,
    define_preview = function(self, entry, status)
      local endpoint = entry.value
      if not endpoint or not endpoint.file_path then
        return
      end
      
      -- Read file content
      conf.buffer_previewer_maker(endpoint.file_path, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
        callback = function(bufnr)
          -- Highlight the endpoint line
          if endpoint.line_number then
            vim.api.nvim_buf_add_highlight(
              bufnr,
              -1,
              "TelescopePreviewMatch",
              endpoint.line_number - 1,
              math.max(0, (endpoint.column or 1) - 1),
              -1
            )
          end
          
          -- Set cursor to the endpoint line
          if self.state.winid and vim.api.nvim_win_is_valid(self.state.winid) then
            vim.api.nvim_win_set_cursor(self.state.winid, { 
              endpoint.line_number or 1, 
              math.max(0, (endpoint.column or 1) - 1) 
            })
          end
        end
      })
    end,
  })
end

return M