-- UI themes and styling
local M = {}

-- Get method color from config
function M.get_method_color(method, config)
  local colors = config.ui.method_colors
  return colors[method] or "TelescopeResultsIdentifier"
end

-- Get method icon from config
function M.get_method_icon(method, config)
  if not config.ui.show_icons then
    return ""
  end
  local icons = config.ui.method_icons
  return icons[method] or "⚪"
end

-- Get method text from config
function M.get_method_text(method, config)
  if not config.ui.show_method then
    return ""
  end
  return method
end

-- Default method colors
M.DEFAULT_METHOD_COLORS = {
  GET = "TelescopeResultsNumber", -- Default: Green-ish
  POST = "TelescopeResultsConstant", -- Default: Blue-ish
  PUT = "TelescopeResultsKeyword", -- Default: Orange-ish
  DELETE = "TelescopeResultsSpecialChar", -- Default: Red-ish
  PATCH = "TelescopeResultsFunction", -- Default: Purple-ish
}

-- Default method icons
M.DEFAULT_METHOD_ICONS = {
  GET = "📥",
  POST = "📤",
  PUT = "✏️",
  DELETE = "🗑️",
  PATCH = "🔧",
}

return M
