local fs = require "endpoint.utils.fs"
local core_base = require "endpoint.core.base"

-- Required methods that cache implementations must provide
local required_methods = {
  "is_cache_valid",
  "should_use_cache",
  "clear_for_realtime_mode",
  "save_to_file",
  "load_from_file",
}

-- Create base class for cache implementations
---@class endpoint.CacheBase
local M = core_base.create_base(required_methods) ---@diagnostic disable-line: assign-type-mismatch
local find_table = {}
local preview_table = {}
local cache_timestamp = {}

local MAX_CACHE_ENTRIES = 1000
local MAX_PREVIEW_ENTRIES = 200
local access_order = {}
---@return table
function M:get_cache_config()
  local ok, state = pcall(require, "endpoint.core.state")
  if ok then
    local config = state.get_config()
    if config then
      return {
        mode = config.cache_mode or "none",
      }
    end
  end

  local config_ok, default_config = pcall(require, "endpoint.core.config")
  if config_ok then
    return {
      mode = default_config.cache_mode or "none",
    }
  end

  return {
    mode = "none",
  }
end

---@param cache_table table
---@param max_entries number
---@param name string
function M:cleanup_cache_by_size(cache_table, max_entries, name)
  local count = 0
  for _ in pairs(cache_table) do
    count = count + 1
  end

  if count > max_entries then
    local keys_to_remove = {}
    local excess = count - max_entries

    for _ = 1, excess do
      local oldest_key = access_order[name] and access_order[name][1]
      if oldest_key and cache_table[oldest_key] then
        table.insert(keys_to_remove, oldest_key)
        table.remove(access_order[name], 1)
      end
    end

    for _, key in ipairs(keys_to_remove) do
      cache_table[key] = nil
    end
  end
end

---@param cache_name string
---@param key string
function M:track_access(cache_name, key)
  if not access_order[cache_name] then
    access_order[cache_name] = {}
  end

  for i, existing_key in ipairs(access_order[cache_name]) do
    if existing_key == key then
      table.remove(access_order[cache_name], i)
      break
    end
  end

  table.insert(access_order[cache_name], key)
end

---@return string
function M:get_project_cache_dir()
  local project_root = fs.get_project_root()
  local project_name = vim.fn.fnamemodify(project_root, ":t")
  return vim.fn.stdpath "data" .. "/endpoint.nvim/" .. project_name
end

---@return table
function M:get_cache_files()
  local cache_dir = self:get_project_cache_dir()
  return {
    cache_dir = cache_dir,
    find_cache_file = cache_dir .. "/find_cache.lua",
    metadata_file = cache_dir .. "/metadata.lua",
  }
end

function M:ensure_cache_dir()
  local cache_dir = self:get_project_cache_dir()
  vim.fn.mkdir(cache_dir, "p")
end

function M:migrate_framework_keys(timestamp_data)
  if not timestamp_data then
    return {}
  end

  local migrated = {}
  local methods = { "GET", "POST", "PUT", "DELETE", "PATCH" }

  for key, value in pairs(timestamp_data) do
    local framework_method = key:match "^%w+_([A-Z]+)$"
    if framework_method then
      for _, method in ipairs(methods) do
        if framework_method == method then
          migrated[method] = value
          break
        end
      end
    else
      migrated[key] = value
    end
  end

  return migrated
end
function M:get_find_table()
  return find_table
end

function M:get_preview_table()
  return preview_table
end

function M:get_cache_timestamp()
  return cache_timestamp
end

function M:set_cache_timestamp(data)
  cache_timestamp = data or {}
end

function M:clear_tables()
  find_table = {}
  preview_table = {}
  cache_timestamp = {}
  access_order = {}
end

function M:create_find_table_entry(path, annotation)
  if not find_table[path] then
    find_table[path] = {}
  end

  if not find_table[path][annotation] then
    find_table[path][annotation] = {}
  end

  local cache_config = self:get_cache_config()
  if cache_config.mode ~= "none" then
    self:track_access("find_table", path)
    self:cleanup_cache_by_size(find_table, MAX_CACHE_ENTRIES, "find_table")
  end
end

function M:insert_to_find_table(opts)
  table.insert(
    find_table[opts.path][opts.annotation],
    { value = opts.value, line_number = opts.line_number, column = opts.column }
  )
end

function M:insert_to_find_request_table(opts)
  find_table[opts.path][opts.annotation] = { value = opts.value, line_number = opts.line_number, column = opts.column }
end

function M:create_preview_entry(endpoint, path, line_number, column)
  preview_table[endpoint] = {
    path = path,
    line_number = line_number,
    column = column,
  }

  local cache_config = self:get_cache_config()
  if cache_config.mode ~= "none" then
    self:track_access("preview_table", endpoint)
    self:cleanup_cache_by_size(preview_table, MAX_PREVIEW_ENTRIES, "preview_table")
  end
end

function M:update_cache_timestamp(annotation)
  cache_timestamp[annotation] = os.time()
end
function M:get_cache_stats()
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
    max_find_entries = MAX_CACHE_ENTRIES,
    max_preview_entries = MAX_PREVIEW_ENTRIES,
    find_usage_percent = math.floor((find_count / MAX_CACHE_ENTRIES) * 100),
    preview_usage_percent = math.floor((preview_count / MAX_PREVIEW_ENTRIES) * 100),
  }
end

-- Required methods are automatically validated by core_base

return M
