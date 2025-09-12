-- Simplified cache implementation (function-based)
local M = {}

-- Cache data
local find_table = {}
local preview_table = {}
local timestamp = {}
local mode = "session"

-- Configuration
function M.set_mode(cache_mode)
  mode = cache_mode or "session"
  if mode == "persistent" then
    M.load_from_file()
  end
end

function M.get_mode()
  return mode
end

-- Cache validation
function M.is_valid(key)
  if mode == "none" then
    return false
  end

  -- Check if we have any data for this method
  local has_data = false

  if key == "ALL" then
    -- For ALL, check if we have any data at all
    for _, methods in pairs(find_table) do
      for _, method_data in pairs(methods) do
        local endpoints = method_data.endpoints or method_data
        if type(endpoints) == "table" and #endpoints > 0 then
          has_data = true
          break
        end
      end
      if has_data then
        break
      end
    end
  else
    -- For specific method, check if we have data for that method
    for _, methods in pairs(find_table) do
      if methods[key] then
        -- Handle both old format (array) and new format (table with endpoints)
        local endpoints = methods[key].endpoints or methods[key]
        if type(endpoints) == "table" and #endpoints > 0 then
          has_data = true
          break
        end
      end
    end
  end

  if not has_data then
    return false
  end

  -- For persistent mode, cache is always valid if data exists
  if mode == "persistent" then
    return true
  end

  -- For session mode, check timestamp
  if key == "ALL" then
    -- For ALL, check if any method has a valid timestamp
    for method, _ in pairs(timestamp) do
      if timestamp[method] ~= nil then
        return true
      end
    end
    return false
  else
    return timestamp[key] ~= nil
  end
end

-- Data operations
function M.save_endpoint(method, endpoint)
  if mode == "none" then
    return
  end

  -- Initialize tables
  if not find_table[endpoint.file_path] then
    find_table[endpoint.file_path] = {}
  end
  if not find_table[endpoint.file_path][method] then
    find_table[endpoint.file_path][method] = {
      endpoints = {}, -- Array for iteration
      unique_set = {}, -- Hash set for O(1) duplicate checking
    }
  end

  -- Create unique key to prevent duplicates
  local unique_key = string.format("%s:%d:%d", endpoint.endpoint_path, endpoint.line_number or 0, endpoint.column or 0)

  local method_data = find_table[endpoint.file_path][method]

  -- Handle backward compatibility: convert old format to new format
  if not method_data.endpoints then
    -- Old format: method_data is an array
    local old_data = method_data
    method_data = {
      endpoints = old_data,
      unique_set = {},
    }
    find_table[endpoint.file_path][method] = method_data

    -- Populate unique_set from existing data
    for _, existing in ipairs(old_data) do
      local existing_key = string.format("%s:%d:%d", existing.value, existing.line_number or 0, existing.column or 0)
      method_data.unique_set[existing_key] = true
    end
  end

  -- Only add if it doesn't exist (O(1) lookup)
  if not method_data.unique_set[unique_key] then
    local endpoint_data = {
      value = endpoint.endpoint_path,
      line_number = endpoint.line_number,
      column = endpoint.column,
    }

    table.insert(method_data.endpoints, endpoint_data)
    method_data.unique_set[unique_key] = true
  end

  -- Update timestamp
  timestamp[method] = os.time()

  -- Note: For persistent mode, we'll save at the end of scanning
  -- to avoid frequent file I/O operations during endpoint collection
end

function M.save_preview(endpoint_key, file_path, line_number, column)
  if mode == "none" then
    return
  end

  preview_table[endpoint_key] = {
    path = file_path,
    line_number = line_number,
    column = column,
  }
end

function M.get_endpoints(method)
  local results = {}

  for path, methods in pairs(find_table) do
    if method == "ALL" then
      -- Return all methods for ALL request
      for http_method, method_data in pairs(methods) do
        -- Handle both old format (array) and new format (table with endpoints)
        local endpoints = method_data.endpoints or method_data

        for _, item in ipairs(endpoints) do
          table.insert(results, {
            file_path = path,
            method = http_method,
            endpoint_path = item.value,
            line_number = item.line_number,
            column = item.column,
            display_value = http_method .. " " .. item.value,
          })
        end
      end
    elseif methods[method] then
      -- Return specific method
      -- Handle both old format (array) and new format (table with endpoints)
      local endpoints = methods[method].endpoints or methods[method]

      for _, item in ipairs(endpoints) do
        table.insert(results, {
          file_path = path,
          method = method,
          endpoint_path = item.value,
          line_number = item.line_number,
          column = item.column,
          display_value = method .. " " .. item.value,
        })
      end
    end
  end

  return results
end

function M.get_preview(endpoint_key)
  return preview_table[endpoint_key]
end

function M.get_find_table()
  return find_table
end

function M.get_preview_table()
  return preview_table
end

-- File operations for persistent mode
function M.save_to_file()
  if mode ~= "persistent" then
    return
  end

  local fs = require "endpoint.utils.fs"
  local project_root = fs.get_project_root()
  local project_name = vim.fn.fnamemodify(project_root, ":t")
  local cache_dir = vim.fn.stdpath "data" .. "/endpoint.nvim/" .. project_name

  vim.fn.mkdir(cache_dir, "p")

  -- Save find table
  local find_file = io.open(cache_dir .. "/find_cache.lua", "w")
  if find_file then
    find_file:write("return " .. vim.inspect(find_table))
    find_file:close()
  end

  -- Save metadata
  local metadata = {
    project_root = project_root,
    timestamp = timestamp,
  }
  local meta_file = io.open(cache_dir .. "/metadata.lua", "w")
  if meta_file then
    meta_file:write("return " .. vim.inspect(metadata))
    meta_file:close()
  end
end

function M.load_from_file()
  if mode ~= "persistent" then
    return
  end

  local fs = require "endpoint.utils.fs"
  local project_root = fs.get_project_root()
  local project_name = vim.fn.fnamemodify(project_root, ":t")
  local cache_dir = vim.fn.stdpath "data" .. "/endpoint.nvim/" .. project_name

  -- Load find table
  local find_file = cache_dir .. "/find_cache.lua"
  if fs.file_exists(find_file) then
    local ok, data = pcall(dofile, find_file)
    if ok and data then
      find_table = data
      -- Set timestamp for loaded data
      for _, methods in pairs(find_table) do
        for method, _ in pairs(methods) do
          timestamp[method] = os.time()
        end
      end
    end
  end

  -- Load metadata
  local meta_file = cache_dir .. "/metadata.lua"
  if fs.file_exists(meta_file) then
    local ok, data = pcall(dofile, meta_file)
    if ok and data and data.timestamp then
      -- Use saved timestamps if available
      for method, time in pairs(data.timestamp) do
        timestamp[method] = time
      end
    end
  end
end

-- Utility functions
function M.clear()
  find_table = {}
  preview_table = {}
  timestamp = {}
end

function M.clear_persistent_cache()
  M.clear()
  if mode == "persistent" then
    local fs = require "endpoint.utils.fs"
    local project_root = fs.get_project_root()
    local project_name = vim.fn.fnamemodify(project_root, ":t")
    local cache_dir = vim.fn.stdpath "data" .. "/endpoint.nvim/" .. project_name

    -- Remove cache files
    local find_file = cache_dir .. "/find_cache.lua"
    local meta_file = cache_dir .. "/metadata.lua"

    if fs.file_exists(find_file) then
      vim.fn.delete(find_file)
    end

    if fs.file_exists(meta_file) then
      vim.fn.delete(meta_file)
    end
  end
end

function M.get_stats()
  local find_count = 0
  local preview_count = 0

  for _ in pairs(find_table) do
    find_count = find_count + 1
  end

  for _ in pairs(preview_table) do
    preview_count = preview_count + 1
  end

  return {
    find_entries = find_count,
    preview_entries = preview_count,
    mode = mode,
    timestamps = vim.tbl_keys(timestamp),
  }
end

return M
