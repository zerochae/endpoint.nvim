local cache_manager = require "endpoint.cache.manager"

local M = {}

local function get_current_cache()
  return cache_manager.get_current()
end

M.clear_tables = function()
  return get_current_cache():clear_tables()
end

M.clear_for_realtime_mode = function()
  return get_current_cache():clear_for_realtime_mode()
end

M.get_find_table = function()
  return get_current_cache():get_find_table()
end

M.get_preview_table = function()
  return get_current_cache():get_preview_table()
end

M.is_cache_valid = function(key, config)
  return get_current_cache():is_cache_valid(key, config)
end

M.update_cache_timestamp = function(annotation)
  return get_current_cache():update_cache_timestamp(annotation)
end

M.should_use_cache = function(key, config)
  return get_current_cache():should_use_cache(key, config)
end

M.create_find_table_entry = function(path, annotation)
  return get_current_cache():create_find_table_entry(path, annotation)
end

M.insert_to_find_table = function(opts)
  return get_current_cache():insert_to_find_table(opts)
end

M.insert_to_find_request_table = function(opts)
  return get_current_cache():insert_to_find_request_table(opts)
end

M.create_preview_entry = function(endpoint, path, line_number, column)
  return get_current_cache():create_preview_entry(endpoint, path, line_number, column)
end

M.batch_create_preview_entries = function(entries)
  return get_current_cache():batch_create_preview_entries(entries)
end

M.save_to_file = function()
  return get_current_cache():save_to_file()
end

M.load_from_file = function()
  return get_current_cache():load_from_file()
end

M.get_cache_stats = function()
  return get_current_cache():get_cache_stats()
end

M.clear_persistent_cache = function()
  local persistent_cache = cache_manager.get "persistent"
  return persistent_cache:clear_persistent_cache()
end

M.get_scanned_methods = function()
  local persistent_cache = cache_manager.get "persistent"
  return persistent_cache:get_scanned_methods()
end

M.get_missing_methods = function(required_methods)
  return get_current_cache():get_missing_methods(required_methods)
end

M.show_cache_status = function()
  local cache_status_ui = require "endpoint.ui.cache_status"
  return cache_status_ui.show_cache_status()
end

return M
