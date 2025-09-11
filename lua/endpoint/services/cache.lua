local M = {}

local find_table = {}
local preview_table = {}
local cache_timestamp = {}

-- Cache configuration helper
local get_cache_config = function()
  local session = require "endpoint.core.session"
  local config = session.get_config()

  if not config then
    -- Fallback to default config if session is not initialized
    local default_config = require "endpoint.core.config"
    return {
      mode = default_config.cache_mode or "none",
    }
  end

  return {
    mode = config.cache_mode or "none", -- Default real-time (no cache)
  }
end

-- Lazy initialization flag
local cache_initialized = false

-- Initialize cache when first accessed
local function ensure_cache_initialized()
  if cache_initialized then
    return
  end
  
  cache_initialized = true
  local cache_config = get_cache_config()
  if cache_config.mode == "persistent" then
    M.load_from_file()
  else
  end
end

-- Memory management configuration
local MAX_CACHE_ENTRIES = 1000 -- Maximum number of cache entries per type
local MAX_PREVIEW_ENTRIES = 200 -- Lower limit for preview cache (memory heavy)
local access_order = {} -- Track access order for LRU cleanup

-- Persistent cache configuration
local function get_project_root()
  local result = vim.fn.system "git rev-parse --show-toplevel 2>/dev/null"
  if vim.v.shell_error ~= 0 then
    return vim.fn.getcwd() -- fallback to current directory
  end
  return result:gsub("\n", "")
end

local function get_project_cache_dir()
  local project_root = get_project_root()
  local project_name = vim.fn.fnamemodify(project_root, ":t")
  return vim.fn.stdpath "data" .. "/endpoint.nvim/" .. project_name
end

local function get_cache_files()
  local cache_dir = get_project_cache_dir()
  return {
    cache_dir = cache_dir,
    find_cache_file = cache_dir .. "/find_cache.lua",
    metadata_file = cache_dir .. "/metadata.lua",
  }
end

-- Memory cleanup functions
local function cleanup_cache_by_size(cache_table, max_entries, name)
  local count = 0
  for _ in pairs(cache_table) do
    count = count + 1
  end

  if count > max_entries then
    local keys_to_remove = {}
    local excess = count - max_entries

    -- Remove least recently accessed entries
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

-- Track access for LRU
local function track_access(cache_name, key)
  if not access_order[cache_name] then
    access_order[cache_name] = {}
  end

  -- Remove if already exists
  for i, existing_key in ipairs(access_order[cache_name]) do
    if existing_key == key then
      table.remove(access_order[cache_name], i)
      break
    end
  end

  -- Add to end (most recent)
  table.insert(access_order[cache_name], key)
end

M.clear_tables = function()
  find_table = {}
  preview_table = {}
  cache_timestamp = {}
  access_order = {}
  endpoint_cache = {}
  temp_find_table = {}
  temp_preview_table = {}
end

-- Clear temp table for real-time mode
M.clear_temp_table = function()
  temp_find_table = {}
  temp_preview_table = {}
end

-- Ensure temp_find_table is initialized
local function ensure_temp_table_initialized()
  if not temp_find_table then
    temp_find_table = {}
  end
end

M.get_find_table = function()
  -- Check cache mode - if "none", return temp table
  local cache_config = get_cache_config()
  if cache_config.mode == "none" then
    -- Ensure temp_find_table is initialized
    if not temp_find_table then
      temp_find_table = {}
    end
    return temp_find_table
  end
  
  ensure_cache_initialized()
  -- Track access for potential cleanup
  track_access("find_table", "global_access")
  return find_table
end

M.get_preview_table = function()
  -- Check cache mode - if "none", return temp preview table
  local cache_config = get_cache_config()
  if cache_config.mode == "none" then
    -- Ensure temp_preview_table is initialized
    if not temp_preview_table then
      temp_preview_table = {}
    end
    return temp_preview_table
  end
  
  -- Track access for potential cleanup
  track_access("preview_table", "global_access")
  return preview_table
end

-- Helper functions for persistent cache
local function ensure_cache_dir()
  local cache_dir = get_project_cache_dir()
  vim.fn.mkdir(cache_dir, "p")
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

M.is_cache_valid = function(key)
  ensure_cache_initialized()
  local cache_config = get_cache_config()
  local cached_time = cache_timestamp[key]


  if cache_config.mode == "persistent" then
    local cache_files = get_cache_files()
    local file_exists_result = file_exists(cache_files.find_cache_file)
    
    -- In persistent mode, check if cache file exists and has been loaded
    -- If timestamp exists for this key, cache is valid
    -- If no timestamp but find_table has data and cache file exists, also valid
    if cached_time ~= nil then
      local result = file_exists_result
      return result
    else
      local result = next(find_table) ~= nil and file_exists_result
      return result
    end
  else -- session mode
    local result = cached_time ~= nil
    return result
  end
end

M.update_cache_timestamp = function(annotation)
  -- Always use timestamp for unified tracking
  cache_timestamp[annotation] = os.time()
end

M.should_use_cache = function(key)
  ensure_cache_initialized()
  local result = M.is_cache_valid(key)
  return result
end

M.create_find_table_entry = function(path, annotation)
  local cache_config = get_cache_config()
  
  if cache_config.mode == "none" then
    -- Ensure temp_find_table is initialized
    if not temp_find_table then
      temp_find_table = {}
    end
    -- Use temp table for real-time mode
    if not temp_find_table[path] then
      temp_find_table[path] = {}
    end
    if not temp_find_table[path][annotation] then
      temp_find_table[path][annotation] = {}
    end
    return
  end
  
  if not find_table[path] then
    find_table[path] = {}
  end

  if not find_table[path][annotation] then
    find_table[path][annotation] = {}
  end

  track_access("find_table", path)
  cleanup_cache_by_size(find_table, MAX_CACHE_ENTRIES, "find_table")
end

M.insert_to_find_table = function(opts)
  local cache_config = get_cache_config()
  
  if cache_config.mode == "none" then
    -- Ensure temp_find_table is initialized
    if not temp_find_table then
      temp_find_table = {}
    end
    -- Use temp table for real-time mode
    table.insert(
      temp_find_table[opts.path][opts.annotation],
      { value = opts.value, line_number = opts.line_number, column = opts.column }
    )
    return
  end
  
  table.insert(
    find_table[opts.path][opts.annotation],
    { value = opts.value, line_number = opts.line_number, column = opts.column }
  )
end

M.insert_to_find_request_table = function(opts)
  local cache_config = get_cache_config()
  
  if cache_config.mode == "none" then
    -- Ensure temp_find_table is initialized
    if not temp_find_table then
      temp_find_table = {}
    end
    -- Use temp table for real-time mode
    temp_find_table[opts.path][opts.annotation] = { value = opts.value, line_number = opts.line_number, column = opts.column }
    return
  end
  
  find_table[opts.path][opts.annotation] = { value = opts.value, line_number = opts.line_number, column = opts.column }
end

M.create_preview_entry = function(endpoint, path, line_number, column)
  local cache_config = get_cache_config()
  
  if cache_config.mode == "none" then
    -- Ensure temp_preview_table is initialized
    if not temp_preview_table then
      temp_preview_table = {}
    end
    -- Use temp table for real-time mode
    temp_preview_table[endpoint] = {
      path = path,
      line_number = line_number,
      column = column,
    }
    return
  end
  
  preview_table[endpoint] = {
    path = path,
    line_number = line_number,
    column = column,
  }

  track_access("preview_table", endpoint)
  cleanup_cache_by_size(preview_table, MAX_PREVIEW_ENTRIES, "preview_table")
end

-- Persistent cache functions
M.save_to_file = function()
  local cache_config = get_cache_config()
  if cache_config.mode ~= "persistent" then
    return
  end

  debug_log "Saving cache to file"
  ensure_cache_dir()
  local cache_files = get_cache_files()

  -- Save find table
  local find_file = io.open(cache_files.find_cache_file, "w")
  if find_file then
    find_file:write("return " .. vim.inspect(find_table))
    find_file:close()
  end

  -- Save metadata
  local metadata = {
    project_root = get_project_root(),
    timestamp = cache_timestamp,
  }

  local meta_file = io.open(cache_files.metadata_file, "w")
  if meta_file then
    meta_file:write("return " .. vim.inspect(metadata))
    meta_file:close()
  end
end

-- Migration helper for legacy framework-specific keys
local function migrate_framework_keys(timestamp_data)
  if not timestamp_data then
    return {}
  end

  local migrated = {}
  local methods = { "GET", "POST", "PUT", "DELETE", "PATCH" }

  for key, value in pairs(timestamp_data) do
    -- Check if it's a framework-specific key (e.g., "spring_GET", "nestjs_POST")
    local framework_method = key:match "^%w+_([A-Z]+)$"
    if framework_method then
      -- Convert to generic method key
      for _, method in ipairs(methods) do
        if framework_method == method then
          migrated[method] = value
          break
        end
      end
    else
      -- Keep non-framework-specific keys as-is
      migrated[key] = value
    end
  end

  return migrated
end

M.load_from_file = function()
  local cache_config = get_cache_config()
  if cache_config.mode ~= "persistent" then
    return
  end

  local cache_files = get_cache_files()

  -- Load find table
  if file_exists(cache_files.find_cache_file) then
    local ok, data = pcall(dofile, cache_files.find_cache_file)
    if ok and data then
      find_table = data
    else
    end
  else
  end

  -- Load metadata with migration support
  if file_exists(cache_files.metadata_file) then
    local ok, data = pcall(dofile, cache_files.metadata_file)
    if ok and data then
      if data.timestamp then
        -- Migrate legacy framework-specific keys if they exist
        cache_timestamp = migrate_framework_keys(data.timestamp)
      end

      -- Legacy support: migrate from old scanned_annotations structure
      if data.scanned_annotations and not next(cache_timestamp) then
        cache_timestamp = data.scanned_annotations
      end
    else
    end
  else
  end
end

M.clear_persistent_cache = function()
  -- Clear memory cache
  M.clear_tables()

  local cache_files = get_cache_files()

  -- Remove cache files
  if file_exists(cache_files.find_cache_file) then
    vim.fn.delete(cache_files.find_cache_file)
  end
  if file_exists(cache_files.metadata_file) then
    vim.fn.delete(cache_files.metadata_file)
  end

  -- Remove cache directory if empty
  local cache_dir = cache_files.cache_dir
  if vim.fn.isdirectory(cache_dir) == 1 and vim.fn.empty(vim.fn.glob(cache_dir .. "/*")) == 1 then
    vim.fn.delete(cache_dir, "d")
  end
end

-- Get which methods have been scanned (for intelligent cache management)
M.get_scanned_methods = function()
  -- Always use cache_timestamp for unified tracking
  return vim.tbl_keys(cache_timestamp)
end

-- Check if specific methods need scanning
M.get_missing_methods = function(required_methods)
  ensure_cache_initialized() -- Make sure cache is initialized first!
  
  local scanned_methods = M.get_scanned_methods()


  local scanned_set = {}
  for _, method in ipairs(scanned_methods) do
    scanned_set[method] = true
  end

  -- In persistent mode, if find_table has data but cache_timestamp is empty,
  -- we should consider all methods as already scanned
  local cache_config = get_cache_config()
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

-- Get memory usage stats
M.get_cache_stats = function()
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

M.show_cache_status = function()
  -- Use the new pretty UI
  local cache_status_ui = require "endpoint.ui.cache_status"
  return cache_status_ui.show_cache_status()
end

-- New unified cache interface for endpoint results
local endpoint_cache = {}

-- Temporary storage for real-time mode
local temp_find_table = {}
local temp_preview_table = {}

M.get_cached_results = function(cache_key, config)
  -- If cache mode is "none", never return cached results
  if config and config.cache_mode == "none" then
    return nil
  end

  ensure_cache_initialized()
  
  local cache_config = get_cache_config()
  if config and config.cache_mode then
    cache_config.mode = config.cache_mode
  end

  -- Check if we should use cache based on mode and validity
  if not M.is_cache_valid(cache_key) then
    return nil
  end

  return endpoint_cache[cache_key]
end

M.set_cached_results = function(cache_key, results, config)
  -- If cache mode is "none", never cache results
  if config and config.cache_mode == "none" then
    return
  end

  ensure_cache_initialized()
  
  endpoint_cache[cache_key] = results
  M.update_cache_timestamp(cache_key)

  -- Save to file if in persistent mode
  local cache_config = get_cache_config()
  if config and config.cache_mode then
    cache_config.mode = config.cache_mode
  end

  if cache_config.mode == "persistent" then
    M.save_to_file()
  end
end

return M
