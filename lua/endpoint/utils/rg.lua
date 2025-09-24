-- Ripgrep command utility functions
local M = {}

-- Generate ripgrep search command for endpoint patterns
function M.create_command(ripgrep_search_options)
  local method_patterns = ripgrep_search_options.method_patterns or {}
  local file_globs = ripgrep_search_options.file_globs or {}
  local exclude_globs = ripgrep_search_options.exclude_globs or {}
  local extra_flags = ripgrep_search_options.extra_flags or {}

  -- Always search all patterns comprehensively
  local all_search_patterns = {}
  for _, pattern_list in pairs(method_patterns) do
    for _, search_pattern in ipairs(pattern_list) do
      table.insert(all_search_patterns, search_pattern)
    end
  end

  if #all_search_patterns == 0 then
    return ""
  end

  -- Base ripgrep command with essential flags
  local ripgrep_command = "rg --line-number --column --no-heading --color=never"

  -- Add extra command flags
  for _, command_flag in ipairs(extra_flags) do
    ripgrep_command = ripgrep_command .. " " .. command_flag
  end

  -- Add file inclusion patterns
  for _, file_glob_pattern in ipairs(file_globs) do
    ripgrep_command = ripgrep_command .. " --glob '" .. file_glob_pattern .. "'"
  end

  -- Add file exclusion patterns
  for _, exclude_glob_pattern in ipairs(exclude_globs) do
    ripgrep_command = ripgrep_command .. " --glob '!" .. exclude_glob_pattern .. "/**'"
  end

  -- Add all search patterns to command
  for _, search_pattern in ipairs(all_search_patterns) do
    ripgrep_command = ripgrep_command .. " -e '" .. search_pattern .. "'"
  end

  -- Add search path (current directory)
  ripgrep_command = ripgrep_command .. " ."

  return ripgrep_command
end

-- Common exclude patterns for different project types
M.common_exclude_patterns = {
  node = { "**/node_modules", "**/dist", "**/build" },
  java = { "**/target", "**/build", "**/.gradle" },
  python = { "**/__pycache__", "**/venv", "**/.venv", "**/site-packages" },
  php = { "**/vendor", "**/cache" },
  ruby = { "**/vendor/bundle", "**/tmp" },
}

-- Common file patterns for different languages
M.common_file_patterns = {
  javascript = { "**/*.js", "**/*.ts", "**/*.jsx", "**/*.tsx", "**/*.mjs" },
  java = { "**/*.java" },
  python = { "**/*.py" },
  php = { "**/*.php" },
  ruby = { "**/*.rb" },
  react = { "**/*.js", "**/*.jsx", "**/*.ts", "**/*.tsx" },
}

return M
