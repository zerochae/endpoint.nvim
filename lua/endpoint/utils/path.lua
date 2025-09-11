-- Path utilities
local M = {}

-- Combine base path and endpoint path
function M.combine_paths(base, endpoint)
  if not base or base == "" then
    return endpoint or ""
  end
  if not endpoint or endpoint == "" then
    return base
  end

  -- Avoid double slashes
  if base:sub(-1) == "/" then
    base = base:sub(1, -2)
  end
  if endpoint:sub(1, 1) ~= "/" then
    endpoint = "/" .. endpoint
  end

  return base .. endpoint
end

-- Check if current path matches any framework_paths patterns
function M.match_framework_paths(current_path, framework_paths)
  for path_pattern, framework in pairs(framework_paths) do
    -- Simple wildcard matching (* at the end)
    if path_pattern:sub(-1) == "*" then
      local pattern_prefix = path_pattern:sub(1, -2)
      if current_path:sub(1, #pattern_prefix) == pattern_prefix then
        return framework
      end
    else
      -- Exact path matching
      if current_path == path_pattern then
        return framework
      end
    end
  end
  return nil
end

-- Normalize path separators
function M.normalize_path(path)
  return path:gsub("\\", "/")
end

-- Get relative path from root
function M.get_relative_path(filepath, root_path)
  root_path = root_path or vim.fn.getcwd()
  if filepath:sub(1, #root_path) == root_path then
    local relative = filepath:sub(#root_path + 1)
    if relative:sub(1, 1) == "/" then
      relative = relative:sub(2)
    end
    return relative
  end
  return filepath
end

return M
