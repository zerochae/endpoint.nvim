local M = {}

function M.combine_paths(base, endpoint)
  if not base or base == "" then
    return endpoint or ""
  end
  if not endpoint or endpoint == "" then
    return base
  end

  if base:sub(-1) == "/" then
    base = base:sub(1, -2)
  end
  if endpoint:sub(1, 1) ~= "/" then
    endpoint = "/" .. endpoint
  end

  return base .. endpoint
end

function M.match_framework_paths(current_path, framework_paths)
  for path_pattern, framework in pairs(framework_paths) do
    if path_pattern:sub(-1) == "*" then
      local pattern_prefix = path_pattern:sub(1, -2)
      if current_path:sub(1, #pattern_prefix) == pattern_prefix then
        return framework
      end
    else
      if current_path == path_pattern then
        return framework
      end
    end
  end
  return nil
end

function M.normalize_path(path)
  return path:gsub("\\", "/")
end

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
