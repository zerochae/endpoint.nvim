-- Persistent cache - File-based caching that persists across sessions
local cache_base = require "endpoint.cache.base"
local fs = require "endpoint.utils.fs"

---@class CacheRegistryPersistent : endpoint.CacheBase
local M = {}
setmetatable(M, { __index = cache_base })
M.name = "persistent"

-- Lazy initialization flag
local cache_initialized = false

-- Initialize cache when first accessed
function M:ensure_cache_initialized()
  if cache_initialized then
    return
  end

  cache_initialized = true
  local cache_config = self:get_cache_config()
  if cache_config.mode == "persistent" then
    self:load_from_file()
  end
end

function M:is_cache_valid(key, config)
  self:ensure_cache_initialized()
  local cache_config = self:get_cache_config()

  -- Override with provided config if available
  if config and config.cache_mode then
    cache_config.mode = config.cache_mode
  end

  local cache_timestamp = self:get_cache_timestamp()
  local cached_time = cache_timestamp[key]

  if cache_config.mode == "persistent" then
    -- For unit tests, also check if we just have timestamp (don't require file)
    if cached_time ~= nil then
      return true
    end

    -- Check file existence as fallback for real usage
    local cache_files = self:get_cache_files()
    local file_exists_result = fs.file_exists(cache_files.find_cache_file)
    local find_table = self:get_find_table()
    return next(find_table) ~= nil and file_exists_result
  end

  return false
end

function M:should_use_cache(key, config)
  self:ensure_cache_initialized()
  return self:is_cache_valid(key, config)
end

-- Persistent mode doesn't clear for real-time, only none mode does
function M:clear_for_realtime_mode()
  -- Do nothing in persistent mode
end

-- Save cache data to files
function M:save_to_file()
  local cache_config = self:get_cache_config()
  if cache_config.mode ~= "persistent" then
    return
  end

  -- Cache saving to file"
  self:ensure_cache_dir()
  local cache_files = self:get_cache_files()
  local find_table = self:get_find_table()
  local cache_timestamp = self:get_cache_timestamp()

  -- Save find table
  local find_file = io.open(cache_files.find_cache_file, "w")
  if find_file then
    find_file:write("return " .. vim.inspect(find_table))
    find_file:close()
  end

  -- Save metadata
  local metadata = {
    project_root = fs.get_project_root(),
    timestamp = cache_timestamp,
  }

  local meta_file = io.open(cache_files.metadata_file, "w")
  if meta_file then
    meta_file:write("return " .. vim.inspect(metadata))
    meta_file:close()
  end
end

-- Load cache data from files
function M:load_from_file()
  local cache_config = self:get_cache_config()
  if cache_config.mode ~= "persistent" then
    return
  end

  local cache_files = self:get_cache_files()

  -- Load find table
  if fs.file_exists(cache_files.find_cache_file) then
    local ok, data = pcall(dofile, cache_files.find_cache_file)
    if ok and data then
      -- Replace the table content without reassigning the reference
      local find_table = self:get_find_table()
      for k in pairs(find_table) do
        find_table[k] = nil
      end
      for k, v in pairs(data) do
        find_table[k] = v
      end
    end
  end

  -- Load metadata with migration support
  if fs.file_exists(cache_files.metadata_file) then
    local ok, data = pcall(dofile, cache_files.metadata_file)
    if ok and data then
      if data.timestamp then
        -- Migrate legacy framework-specific keys if they exist
        local migrated_timestamp = self:migrate_framework_keys(data.timestamp)
        self:set_cache_timestamp(migrated_timestamp)
      end

      -- Legacy support: migrate from old scanned_annotations structure
      local cache_timestamp = self:get_cache_timestamp()
      if data.scanned_annotations and not next(cache_timestamp) then
        self:set_cache_timestamp(data.scanned_annotations)
      end
    end
  end
end

-- Clear persistent cache files and data
function M:clear_persistent_cache()
  -- Clear memory cache
  self:clear_tables()

  local cache_files = self:get_cache_files()

  -- Remove cache files
  if fs.file_exists(cache_files.find_cache_file) then
    vim.fn.delete(cache_files.find_cache_file)
  end
  if fs.file_exists(cache_files.metadata_file) then
    vim.fn.delete(cache_files.metadata_file)
  end

  -- Remove cache directory if empty
  local cache_dir = cache_files.cache_dir
  if vim.fn.isdirectory(cache_dir) == 1 and vim.fn.empty(vim.fn.glob(cache_dir .. "/*")) == 1 then
    vim.fn.delete(cache_dir, "d")
  end
end

-- Get which methods have been scanned (for intelligent cache management)
function M:get_scanned_methods()
  self:ensure_cache_initialized()

  -- Always use cache_timestamp for unified tracking
  local cache_timestamp = self:get_cache_timestamp()
  return vim.tbl_keys(cache_timestamp)
end

-- Check if specific methods need scanning
function M:get_missing_methods(required_methods)
  self:ensure_cache_initialized() -- Make sure cache is initialized first!

  local scanned_methods = self:get_scanned_methods()

  local scanned_set = {}
  for _, method in ipairs(scanned_methods) do
    scanned_set[method] = true
  end

  -- In persistent mode, if find_table has data but cache_timestamp is empty,
  -- we should consider all methods as already scanned
  local cache_config = self:get_cache_config()
  local find_table = self:get_find_table()
  local cache_timestamp = self:get_cache_timestamp()
  if cache_config.mode == "persistent" and next(find_table) ~= nil and next(cache_timestamp) == nil then
    return {} -- No missing methods
  end

  local missing_methods = {}
  for _, method in ipairs(required_methods) do
    if not scanned_set[method] then
      table.insert(missing_methods, method)
    end
  end

  return missing_methods
end

-- Override cleanup methods to be more conservative in persistent mode
function M:cleanup_cache_by_size(cache_table, max_entries, name)
  -- In persistent mode, use a much larger threshold to avoid premature cleanup
  local conservative_max = max_entries * 3 -- Triple the normal limit
  return cache_base.cleanup_cache_by_size(self, cache_table, conservative_max, name)
end

return M
