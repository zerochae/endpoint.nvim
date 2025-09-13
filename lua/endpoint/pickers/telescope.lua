---@class endpoint.pickers.telescope
local M = {}

-- Check if Telescope is available
---@return boolean
function M.is_available()
  return pcall(require, "telescope")
end

-- Show endpoints in Telescope picker
---@param endpoints endpoint.entry[]
---@param opts? table
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
          if entry.action and entry.display_value and entry.display_value:match "%[#.-%]" then
            -- Rails action annotation: highlight the entire "GET[#action]" part
            local method_with_action = entry.display_value:match "^([^%s]+)"
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
            -- Include action name and controller name in search ordinal for Rails action annotations
            ordinal = entry.endpoint_path .. " " .. entry.method 
              .. (entry.action and (" " .. entry.action) or "")
              .. (entry.controller and (" " .. entry.controller) or "")
              .. (entry.display_value and (" " .. entry.display_value) or ""),
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
            
            -- For React Router with component, navigate to component file
            if endpoint.component_file_path and vim.fn.filereadable(endpoint.component_file_path) == 1 then
              vim.cmd("edit " .. endpoint.component_file_path)
              -- Go to the component definition (typically first line or export line)
              vim.cmd "normal! gg"
              -- Try to find component definition
              local component_name = endpoint.component_name
              if component_name then
                vim.fn.search("\\(const\\|function\\|export default\\).*" .. component_name, "w")
              end
            else
              -- Default behavior: navigate to route definition
              vim.cmd("edit " .. endpoint.file_path)
              vim.api.nvim_win_set_cursor(0, { endpoint.line_number, endpoint.column - 1 })
            end
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
---@return table
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

      -- For React Router with component, preview component file instead of route definition
      local preview_file = endpoint.file_path
      local preview_line = endpoint.line_number
      local preview_col = endpoint.column
      
      if endpoint.component_file_path and vim.fn.filereadable(endpoint.component_file_path) == 1 then
        preview_file = endpoint.component_file_path
        preview_line = 1 -- Start at the top of component file
        preview_col = 1
      end

      -- Read file content
      conf.buffer_previewer_maker(preview_file, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
        callback = function(bufnr)
          -- Clear previous highlights first
          vim.api.nvim_buf_clear_namespace(bufnr, highlight_ns, 0, -1)

          -- For component preview, highlight the component definition
          if endpoint.component_file_path and endpoint.component_name then
            -- Try to find and highlight component definition
            vim.defer_fn(function()
              if vim.api.nvim_buf_is_valid(bufnr) then
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                for line_idx, line in ipairs(lines) do
                  -- Look for component definition patterns
                  if line:match("const%s+" .. endpoint.component_name) or
                     line:match("function%s+" .. endpoint.component_name) or
                     line:match("export%s+default%s+" .. endpoint.component_name) or
                     line:match("export%s+default%s+function%s+" .. endpoint.component_name) then
                    vim.api.nvim_buf_add_highlight(
                      bufnr,
                      highlight_ns,
                      "TelescopePreviewMatch", 
                      line_idx - 1,
                      0,
                      -1
                    )
                    preview_line = line_idx
                    break
                  end
                end
              end
            end, 50)
          else
            -- Default: highlight the endpoint line
            if preview_line then
              vim.api.nvim_buf_add_highlight(
                bufnr,
                highlight_ns,
                "TelescopePreviewMatch",
                preview_line - 1,
                math.max(0, (preview_col or 1) - 1),
                -1
              )
            end
          end

          -- Set cursor to the target line and center it
          if self.state.winid and vim.api.nvim_win_is_valid(self.state.winid) then
            local target_line = preview_line or 1
            local target_col = math.max(0, (preview_col or 1) - 1)

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
