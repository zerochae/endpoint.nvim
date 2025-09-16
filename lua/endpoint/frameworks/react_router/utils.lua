-- React Router Framework Utility Functions
---@class endpoint.frameworks.react_router.utils
local M = {}

local fs = require "endpoint.utils.fs"

-- Find component file with various resolution strategies
---@param component_name string
---@return string|nil
function M.find_component_file(component_name)
  if not component_name then
    return nil
  end

  -- Common file extensions for React components
  local extensions = { ".tsx", ".jsx", ".ts", ".js" }
  -- Common directory patterns for React projects
  local search_dirs = { "src", "app", "components", "pages" }

  -- Strategy 1: Direct file search (e.g., Home.tsx, Home.jsx)
  local function try_direct_file(dir, name)
    for _, ext in ipairs(extensions) do
      local file_path = dir and (dir .. "/" .. name .. ext) or (name .. ext)
      if fs.has_file { file_path } then
        return file_path
      end
    end
    return nil
  end

  -- Strategy 2: Index file search (e.g., Home/index.tsx)
  local function try_index_file(dir, name)
    for _, ext in ipairs(extensions) do
      local file_path = dir and (dir .. "/" .. name .. "/index" .. ext) or (name .. "/index" .. ext)
      if fs.has_file { file_path } then
        return file_path
      end
    end
    return nil
  end

  -- Strategy 3: Recursive search in common directories
  local function try_recursive_search(name)
    for _, search_dir in ipairs(search_dirs) do
      if fs.has_file { search_dir } then
        -- Try direct file in search directory
        local direct = try_direct_file(search_dir, name)
        if direct then
          return direct
        end

        -- Try index file in search directory
        local index = try_index_file(search_dir, name)
        if index then
          return index
        end

        -- Try nested search (e.g., src/components/Home.tsx)
        local nested_dirs = { "components", "pages", "views", "containers" }
        for _, nested in ipairs(nested_dirs) do
          local nested_direct = try_direct_file(search_dir .. "/" .. nested, name)
          if nested_direct then
            return nested_direct
          end

          local nested_index = try_index_file(search_dir .. "/" .. nested, name)
          if nested_index then
            return nested_index
          end
        end
      end
    end
    return nil
  end

  -- Try current directory first
  local current_direct = try_direct_file(nil, component_name)
  if current_direct then
    return current_direct
  end

  local current_index = try_index_file(nil, component_name)
  if current_index then
    return current_index
  end

  -- Try recursive search
  return try_recursive_search(component_name)
end

return M