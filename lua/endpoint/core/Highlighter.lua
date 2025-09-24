local Highlighter = {}
Highlighter.__index = Highlighter

---Creates a new highlighter instance with a namespace
---@param namespace_name string
---@return endpoint.Highlighter
function Highlighter:new(namespace_name)
  local highlighter = setmetatable({}, self)
  highlighter.highlight_ns = vim.api.nvim_create_namespace(namespace_name)
  return highlighter
end

---Check if highlighting is enabled in config
---@param config table
---@return boolean
function Highlighter:is_highlighting_enabled(config)
  local enable_highlighting = config.picker and config.picker.previewer and config.picker.previewer.enable_highlighting

  -- Default to true if not configured
  if enable_highlighting == nil then
    enable_highlighting = true
  end

  return enable_highlighting
end

---Clear all highlights in buffer
---@param bufnr number
function Highlighter:clear_highlights(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, self.highlight_ns, 0, -1)
end

---Highlight a specific line range in buffer
---@param bufnr number
---@param start_line number (1-based)
---@param start_col number (1-based)
---@param end_line number|nil (1-based, optional)
---@param highlight_group string|nil
function Highlighter:highlight_line_range(bufnr, start_line, start_col, end_line, highlight_group)
  highlight_group = highlight_group or "TelescopePreviewMatch"

  if start_line then
    local start_line_0 = start_line - 1
    local end_line_0 = end_line and (end_line - 1) or start_line_0
    local start_col_0 = math.max(0, (start_col or 1) - 1)

    -- Highlight multiple lines if end_line is provided
    for line = start_line_0, end_line_0 do
      vim.api.nvim_buf_add_highlight(
        bufnr,
        self.highlight_ns,
        highlight_group,
        line,
        line == start_line_0 and start_col_0 or 0, -- Start from specified column on first line, 0 on others
        -1
      )
    end
  end
end

---Highlight endpoint line(s) based on endpoint data
---@param bufnr number
---@param endpoint table
---@param highlight_group string|nil
function Highlighter:highlight_endpoint(bufnr, endpoint, highlight_group)
  if not endpoint then
    return
  end

  self:highlight_line_range(
    bufnr,
    endpoint.line_number,
    endpoint.column,
    endpoint.end_line_number,
    highlight_group
  )
end

---Highlight component definition in React Router components
---@param bufnr number
---@param endpoint table
---@param highlight_group string|nil
function Highlighter:highlight_component_definition(bufnr, endpoint, highlight_group)
  if not endpoint.component_name then
    return
  end

  highlight_group = highlight_group or "TelescopePreviewMatch"

  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      for line_idx, line in ipairs(lines) do
        -- Look for component definition patterns
        if
          line:match("const%s+" .. endpoint.component_name)
          or line:match("function%s+" .. endpoint.component_name)
          or line:match("export%s+default%s+" .. endpoint.component_name)
          or line:match("export%s+default%s+function%s+" .. endpoint.component_name)
        then
          vim.api.nvim_buf_add_highlight(bufnr, self.highlight_ns, highlight_group, line_idx - 1, 0, -1)
          break
        end
      end
    end
  end, 50)
end

---Calculate highlight length for different display formats (for telescope entries)
---@param entry table
---@param method_icon string
---@param method_text string
---@return number
function Highlighter:calculate_highlight_length(entry, method_icon, method_text)
  if entry.display_value and entry.display_value:match "%[.+#.+%]" then
    -- Rails controller#action annotation: highlight the entire "GET[controller#action]" part
    local method_with_action = entry.display_value:match "^([^%s]+)"
    if method_with_action then
      return #method_icon + #method_with_action + 1
    else
      return #method_icon + #method_text + 1
    end
  elseif entry.action and entry.display_value and entry.display_value:match "%[#.-%]" then
    -- Legacy Rails action annotation: highlight the entire "GET[#action]" part
    local method_with_action = entry.display_value:match "^([^%s]+)"
    if method_with_action then
      return #method_icon + #method_with_action + 1
    else
      return #method_icon + #method_text + 1
    end
  else
    -- Default: just highlight the method
    return #method_icon + #method_text + 1
  end
end

return Highlighter