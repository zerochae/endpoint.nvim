-- Search command utility functions
local M = {}

-- Generate ripgrep search command for endpoint patterns
---@param opts table Options table with method_patterns, file_globs, exclude_globs, extra_flags
---@return string Search command string
function M.create_search_cmd_generator(opts)
  local method_patterns = opts.method_patterns or {}
  local file_globs = opts.file_globs or {}
  local exclude_globs = opts.exclude_globs or {}
  local extra_flags = opts.extra_flags or {}

  -- Always search patterns regardless of method
  local patterns = {}
  for _, pattern_list in pairs(method_patterns) do
    for _, pattern in ipairs(pattern_list) do
      table.insert(patterns, pattern)
    end
  end

  if #patterns == 0 then
    return ""
  end

  -- Base ripgrep command
  local cmd = "rg --line-number --column --no-heading --color=never"

  -- Add extra flags
  for _, flag in ipairs(extra_flags) do
    cmd = cmd .. " " .. flag
  end

  -- Add file include patterns
  for _, glob in ipairs(file_globs) do
    cmd = cmd .. " --glob '" .. glob .. "'"
  end

  -- Add file exclude patterns
  for _, glob in ipairs(exclude_globs) do
    cmd = cmd .. " --glob '!" .. glob .. "/**'"
  end

  -- Add search patterns
  for _, pattern in ipairs(patterns) do
    cmd = cmd .. " -e '" .. pattern .. "'"
  end

  return cmd
end

-- Common exclude patterns for different project types
M.common_excludes = {
  node = { "**/node_modules", "**/dist", "**/build" },
  java = { "**/target", "**/build", "**/.gradle" },
  python = { "**/__pycache__", "**/venv", "**/.venv", "**/site-packages" },
  php = { "**/vendor", "**/cache" },
  ruby = { "**/vendor/bundle", "**/tmp" },
}

-- Common file patterns for different languages
M.common_globs = {
  javascript = { "**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx", "**/*.mjs" },
  java = { "**/*.java" },
  python = { "**/*.py" },
  php = { "**/*.php" },
  ruby = { "**/*.rb" },
  react = { "**/*.js", "**/*.jsx", "**/*.ts", "**/*.tsx" },
}

return M

