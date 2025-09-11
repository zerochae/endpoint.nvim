-- Endpoint Scanner - Clean service for discovering API endpoints
local cache = require("endpoint.services.cache")
local framework_manager = require("endpoint.framework.manager")
local session = require("endpoint.core.session")
local log = require("endpoint.utils.log")

local M = {}

-- Execute ripgrep command with error handling
local function execute_command(cmd)
  log.info("Running command: " .. cmd)
  
  local output = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  log.info("Command exit_code: " .. exit_code .. ", output length: " .. string.len(output))

  if exit_code ~= 0 then
    if exit_code == 1 then
      return "" -- No matches found
    end
    if exit_code == 2 then
      vim.notify("Invalid search pattern or command syntax in: " .. cmd, vim.log.levels.ERROR)
      return nil
    end
    vim.notify("Command failed: " .. cmd .. " (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
    return nil
  end

  return output
end

-- Get framework and config with validation
local function get_framework()
  local config = session.get_config()
  
  -- Fallback: try to get config from core if session doesn't have it
  if not config then
    local ok, core = pcall(require, "endpoint.core")
    if ok and core.get_config then
      config = core.get_config()
    end
  end
  
  -- Ultimate fallback: create a minimal config for tests
  if not config then
    -- Create minimal config without requiring default_config module
    config = {
      cache_mode = "none",
      debug = false,
      framework = "auto",
      methods = { "GET", "POST", "PUT", "DELETE", "PATCH" },
      rg_additional_args = "",
      frameworks = {} -- Will be populated by registry
    }
  end

  local framework_name = framework_manager.get_current_framework_name(config)
  if not framework_name then
    log.warn("No framework detected")
    return nil, nil
  end

  local fw, _, _ = framework_manager.get_current_framework(config)
  return fw, config
end

-- Discover endpoints for a method
local function discover_endpoints(method)
  local framework, config = get_framework()
  if not framework then
    return {}
  end

  local command = framework:get_grep_cmd(method, config)
  local output = execute_command(command)
  
  if not output or output == "" then
    return {}
  end

  local endpoints = {}
  log.info("Processing grep results, lines found: " .. select(2, output:gsub('\n', '\n')) + 1)
  
  for line in vim.gsplit(output, "\n") do
    if line ~= "" then
      log.info("Processing ripgrep line: " .. line)
      local parsed = framework:parse_line(line, method)
      log.info("Parse result: " .. (parsed and vim.inspect(parsed) or "nil"))
      
      if parsed and parsed.endpoint_path and parsed.endpoint_path ~= "" and parsed.endpoint_path:match("%S") then
        table.insert(endpoints, {
          file_path = parsed.file_path,
          method = parsed.method,
          endpoint_path = parsed.endpoint_path,
          line_number = parsed.line_number,
          column = parsed.column,
          display_value = parsed.method .. " " .. parsed.endpoint_path,
        })
      end
    end
  end
  
  return endpoints
end

-- Save endpoints to cache
local function save_to_cache(method, endpoints)
  for _, endpoint in ipairs(endpoints) do
    cache.create_find_table_entry(endpoint.file_path, method)
    cache.insert_to_find_table({
      path = endpoint.file_path,
      annotation = endpoint.method,
      value = endpoint.endpoint_path,
      line_number = endpoint.line_number,
      column = endpoint.column,
    })
  end
  cache.update_cache_timestamp(method)
  cache.save_to_file()
end

-- Public API

-- Scan endpoints for a method
function M.scan(method)
  local config = session.get_config()
  
  -- Clear temp cache for real-time mode
  if config and config.cache_mode == "none" then
    cache.clear_temp_table()
  end

  -- Skip if cache is valid
  if cache.should_use_cache(method, config) then
    return
  end

  -- Discover and cache endpoints
  local endpoints = discover_endpoints(method)
  if #endpoints > 0 then
    save_to_cache(method, endpoints)
  end
end

-- Get endpoints as array (for pickers)
function M.get_list(method)
  M.scan(method)
  
  local finder_table = cache.get_find_table()
  local results = {}
  
  for file_path, mapping_object in pairs(finder_table) do
    if mapping_object[method] then
      local mappings = mapping_object[method]
      if type(mappings) == "table" then
        for _, item in ipairs(mappings) do
          table.insert(results, {
            value = method .. " " .. (item.value or ""),
            method = method,
            path = item.value or "",
            file_path = file_path,
            line_number = item.line_number,
            column = item.column,
          })
        end
      end
    end
  end
  
  return results
end

-- Prepare preview data for UI
function M.prepare_preview(method)
  M.scan(method)
  
  local finder_table = cache.get_find_table()
  
  if method == "ALL" then
    for path, mapping_object in pairs(finder_table) do
      for annotation, mappings in pairs(mapping_object) do
        if type(mappings) == "table" then
          for _, item in ipairs(mappings) do
            local endpoint = annotation .. " " .. (item.value or "")
            cache.create_preview_entry(endpoint, path, item.line_number, item.column)
          end
        end
      end
    end
  else
    for path, mapping_object in pairs(finder_table) do
      if mapping_object[method] then
        local mappings = mapping_object[method]
        if type(mappings) == "table" then
          for _, item in ipairs(mappings) do
            local endpoint = method .. " " .. (item.value or "")
            cache.create_preview_entry(endpoint, path, item.line_number, item.column)
          end
        end
      end
    end
  end
end

-- Batch scan all HTTP methods efficiently
function M.scan_all()
  local framework, config = get_framework()
  if not framework then
    return
  end

  local methods = config.methods or { "GET", "POST", "PUT", "DELETE", "PATCH" }
  local processed_endpoints = {} -- Avoid duplicates
  
  -- Process each method to maintain method-pattern association
  for _, method in ipairs(methods) do
    local patterns = framework:get_patterns(method:lower())
    if patterns and #patterns > 0 then
      local method_pattern = "(" .. table.concat(patterns, "|") .. ")"
      local file_patterns = framework_manager.get_file_patterns(config)
      local exclude_patterns = framework_manager.get_exclude_patterns(config)
      
      local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"
      
      -- Add file patterns
      for _, pattern in ipairs(file_patterns) do
        cmd = cmd .. " --glob '" .. pattern .. "'"
      end
      for _, ex in ipairs(exclude_patterns) do
        cmd = cmd .. " --glob '!" .. ex .. "'"
      end
      if config.rg_additional_args and config.rg_additional_args ~= "" then
        cmd = cmd .. " " .. config.rg_additional_args
      end
      
      cmd = cmd .. " '" .. method_pattern .. "'"
      local output = vim.fn.system(cmd)
      
      if vim.v.shell_error == 0 then
        for line in vim.gsplit(output, "\n") do
          if line ~= "" then
            local parsed = framework:parse_line(line, method:lower())
            if parsed and parsed.endpoint_path and parsed.endpoint_path ~= "" and parsed.endpoint_path:match("%S") then
              local endpoint_key = method .. " " .. parsed.endpoint_path
              
              if not processed_endpoints[endpoint_key] then
                processed_endpoints[endpoint_key] = true
                
                -- Store in cache
                cache.create_find_table_entry(parsed.file_path, method)
                cache.insert_to_find_table({
                  path = parsed.file_path,
                  annotation = parsed.method, -- Use framework-specific method
                  value = parsed.endpoint_path,
                  line_number = parsed.line_number,
                  column = parsed.column,
                })
                
                -- Create preview entry
                cache.create_preview_entry(endpoint_key, parsed.file_path, parsed.line_number, parsed.column)
              end
            end
          end
        end
      end
      
      cache.update_cache_timestamp(method)
    end
  end
  
  cache.save_to_file()
end

-- Cache management
function M.clear_cache()
  cache.clear_tables()
end

function M.get_cache_data()
  return {
    find_table = cache.get_find_table(),
    preview_table = cache.get_preview_table(),
  }
end

return M
