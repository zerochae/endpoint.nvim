local M = {}

local cache = require "endpoint.services.cache"
local framework_manager = require "endpoint.framework.manager"

M.run_cmd = function(cmd)
  -- Debug: ripgrep 명령어 실행 확인
  local debug = require("endpoint.utils.debug")
  debug.info("Running command: " .. cmd)
  
  local output = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  debug.info("Command exit_code: " .. exit_code .. ", output length: " .. string.len(output))

  if exit_code ~= 0 then
    -- Don't show error for common cases like "no matches found" (exit code 1)
    if exit_code == 1 then
      return "" -- Empty result for no matches
    end
    -- Exit code 2 usually means invalid regex or command syntax
    if exit_code == 2 then
      vim.notify("Invalid search pattern or command syntax in: " .. cmd, vim.log.levels.ERROR)
      return nil
    end
    vim.notify("Command failed: " .. cmd .. " (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
    return nil
  end

  return output
end

M.get_method = function(annotation)
  local method = string.upper((annotation):gsub("^@", ""):gsub("Mapping$", ""))
  return method
end

M.clear_tables = function()
  cache.clear_tables()
end

M.get_preview_table = function()
  return cache.get_preview_table()
end

M.get_find_table = function()
  return cache.get_find_table()
end

M.create_endpoint_preview_table = function(method)
  -- Get existing find_table (avoid rescanning)
  local find_table = cache.get_find_table()

  -- If find_table is empty, check cache before scanning
  if not next(find_table) then
    
    if method == "ALL" then
      -- For ALL method, always scan since find_table is empty
      -- The cache initialization should have loaded data if it existed
      
      -- Use batch scan for ALL method
      local batch_scan = require "endpoint.services.batch_scan"
      batch_scan.scan_all_methods()
    else
      -- For single method, check cache first
      if cache.should_use_cache(method) then
        return
      end
      
      -- For single method, check if we can use existing batch scan data
      local session = require "endpoint.core.session"
      local config = session.get_config()

      if not config then
        vim.notify("Session config not available for method: " .. method, vim.log.levels.ERROR)
        return
      end

      local framework_name = framework_manager.get_current_framework_name(config)

      if not framework_name then
        if config.debug then
          vim.notify("No framework detected for method: " .. method, vim.log.levels.WARN)
        end
        return
      end

      local methods = config.methods or { "GET", "POST", "PUT", "DELETE", "PATCH" }

      -- If this method is part of default methods, use batch scan for efficiency
      local is_default_method = false
      for _, m in ipairs(methods) do
        if m == method then
          is_default_method = true
          break
        end
      end

      if is_default_method then
        local batch_scan = require "endpoint.services.batch_scan"
        batch_scan.scan_all_methods()
      else
        -- Single method scan for non-default methods
        M.create_endpoint_table(method)
      end
    end
    find_table = cache.get_find_table()
  end

  -- Convert find_table to preview_table efficiently
  if method == "ALL" then
    -- Create preview entries for all methods
    for path, mapping_object in pairs(find_table) do
      for annotation, mappings in pairs(mapping_object) do
        local current_method = annotation
        if type(mappings) == "table" then
          for _, mapping_item in ipairs(mappings) do
            local endpoint_path = mapping_item.value or ""
            local endpoint = current_method .. " " .. endpoint_path
            cache.create_preview_entry(endpoint, path, mapping_item.line_number, mapping_item.column)
          end
        end
      end
    end
  else
    -- Create preview entries for specific method
    for path, mapping_object in pairs(find_table) do
      if mapping_object[method] then
        local mappings = mapping_object[method]
        if type(mappings) == "table" then
          for _, mapping_item in ipairs(mappings) do
            local endpoint_path = mapping_item.value or ""
            local endpoint = method .. " " .. endpoint_path
            cache.create_preview_entry(endpoint, path, mapping_item.line_number, mapping_item.column)
          end
        end
      end
    end
  end
end

-- Create endpoint table using current framework (new framework-agnostic version)
M.create_endpoint_table = function(method)
  local session = require "endpoint.core.session"
  local config = session.get_config()

  if not config then
    vim.notify("Session config not available", vim.log.levels.ERROR)
    return
  end

  -- Clear temp table for real-time mode
  if config.cache_mode == "none" then
    cache.clear_temp_table()
  end

  local framework_name = framework_manager.get_current_framework_name(config)

  if not framework_name then
    if config.debug then
      vim.notify("No framework detected, skipping endpoint scanning", vim.log.levels.WARN)
    end
    return
  end

  local cache_key = method

  if cache.should_use_cache(cache_key) then
    return
  end

  local fw, _, _ = framework_manager.get_current_framework(config)
  if not fw then
    return
  end

  local cmd = fw:get_grep_cmd(method, config)
  local grep_results = M.run_cmd(cmd)

  if grep_results and grep_results ~= "" then
    local debug = require("endpoint.utils.debug")
    debug.info("Processing grep results, lines found: " .. select(2, grep_results:gsub('\n', '\n')) + 1)
    
    for line in vim.gsplit(grep_results, "\n") do
      if line ~= "" then
        debug.info("Processing ripgrep line: " .. line)
        local parsed = fw:parse_line(line, method, config)
        debug.info("Parse result: " .. (parsed and vim.inspect(parsed) or "nil"))
        
        if parsed and parsed.endpoint_path and parsed.endpoint_path ~= "" and parsed.endpoint_path:match "%S" then
          cache.create_find_table_entry(parsed.file_path, method)
          cache.insert_to_find_table {
            path = parsed.file_path,
            annotation = method,
            value = parsed.endpoint_path,
            line_number = parsed.line_number,
            column = parsed.column,
          }
        end
      end
    end
  end
  cache.update_cache_timestamp(cache_key)
  cache.save_to_file()
end

M.set_cursor_on_entry = function(entry, bufnr, winid)
  local lnum, lnend = entry.lnum - 1, (entry.lnend or entry.lnum) - 1
  local middle_ln = math.floor(lnum + (lnend - lnum) / 2) + 1
  pcall(vim.api.nvim_win_set_cursor, winid, { middle_ln, 0 })
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd "norm! zz"
  end)
end

M.check_duplicate = function(find_table)
  local seen = {}
  local result = {}

  for _, value in ipairs(find_table) do
    if not seen[value] then
      table.insert(result, value)
      seen[value] = true
    end
  end

  return result
end

M.check_duplicate_entries = function(entries)
  local seen = {}
  local result = {}

  for _, entry in ipairs(entries) do
    local key = entry.value
    if not seen[key] then
      table.insert(result, entry)
      seen[key] = true
    end
  end

  return result
end

return M
