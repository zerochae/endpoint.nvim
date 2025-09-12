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
  return timestamp[key] ~= nil
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
    find_table[endpoint.file_path][method] = {}
  end

  -- Save endpoint data
  table.insert(find_table[endpoint.file_path][method], {
    value = endpoint.endpoint_path,
    line_number = endpoint.line_number,
    column = endpoint.column,
  })

  -- Update timestamp
  timestamp[method] = os.time()

  -- Persist if needed
  if mode == "persistent" then
    M.save_to_file()
  end
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
    if methods[method] then
      for _, item in ipairs(methods[method]) do
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
    end
  end

  -- Load metadata
  local meta_file = cache_dir .. "/metadata.lua"
  if fs.file_exists(meta_file) then
    local ok, data = pcall(dofile, meta_file)
    if ok and data and data.timestamp then
      timestamp = data.timestamp
    end
  end
end

-- Utility functions
function M.clear()
  find_table = {}
  preview_table = {}
  timestamp = {}
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

