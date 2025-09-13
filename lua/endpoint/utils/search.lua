-- Search command utility functions
local M = {}

-- Generate ripgrep search command for endpoint patterns
---@param method_patterns table<string, string[]> Method to patterns mapping (e.g., {GET = {"@Get"}, POST = {"@Post"}})
---@param file_globs string[] File glob patterns (e.g., {"**/*.ts", "**/*.js"})
---@param exclude_globs? string[] Exclude glob patterns (e.g., {"**/node_modules/**"})
---@param extra_flags? string[] Additional ripgrep flags (e.g., {"--case-sensitive"})
---@return fun(method: string): string Function that generates search command for given method
function M.create_search_cmd_generator(method_patterns, file_globs, exclude_globs, extra_flags)
  exclude_globs = exclude_globs or {}
  extra_flags = extra_flags or {}
  
  return function(method)
    local patterns = method_patterns[method:upper()] or method_patterns.ALL
    if not patterns then
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