-- High-performance batch scanning for all HTTP methods
local M = {}
local cache = require "endpoint.services.cache"
local framework_manager = require "endpoint.framework.manager"

-- Create a single rg command that searches for all HTTP method patterns at once
function M.scan_all_methods()
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
      vim.notify("No framework detected, skipping batch scan", vim.log.levels.WARN)
    end
    return
  end

  local framework, _, _ = framework_manager.get_current_framework(config)
  if not framework then
    if config.debug then
      vim.notify("Failed to load framework: " .. framework_name, vim.log.levels.ERROR)
    end
    return
  end

  local methods = config.methods or { "GET", "POST", "PUT", "DELETE", "PATCH" }
  local processed_endpoints = {} -- Track processed endpoints to avoid duplicates

  -- Process each method individually to maintain method-pattern association
  for _, method in ipairs(methods) do
    local patterns = framework:get_patterns(method:lower()) -- Convert to lowercase for Spring config
    if patterns and #patterns > 0 then
      -- Create pattern for this specific method
      local method_pattern = "(" .. table.concat(patterns, "|") .. ")"

      local file_patterns = framework_manager.get_file_patterns(config)
      local exclude_patterns = framework_manager.get_exclude_patterns(config)

      local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"

      -- Use file patterns instead of file types
      for _, pattern in ipairs(file_patterns) do
        cmd = cmd .. " --glob '" .. pattern .. "'"
      end
      for _, ex in ipairs(exclude_patterns) do
        cmd = cmd .. " --glob '!" .. ex .. "'"
      end
      if config and config.rg_additional_args and config.rg_additional_args ~= "" then
        cmd = cmd .. " " .. config.rg_additional_args
      end

      cmd = cmd .. " '" .. method_pattern .. "'"
      local output = vim.fn.system(cmd)

      if vim.v.shell_error == 0 then
        -- Parse results for this specific method
        for line in vim.gsplit(output, "\n") do
          if line ~= "" then
            local parsed = framework:parse_line(line, method:lower())
            if parsed and parsed.endpoint_path and parsed.endpoint_path ~= "" and parsed.endpoint_path:match "%S" then
              local endpoint_key = method .. " " .. parsed.endpoint_path

              -- Only process if not already seen
              if not processed_endpoints[endpoint_key] then
                processed_endpoints[endpoint_key] = true

                cache.create_find_table_entry(parsed.file_path, method)
                cache.insert_to_find_table {
                  path = parsed.file_path,
                  annotation = method,
                  value = parsed.endpoint_path,
                  line_number = parsed.line_number,
                  column = parsed.column,
                }

                -- Also create preview entry
                cache.create_preview_entry(endpoint_key, parsed.file_path, parsed.line_number, parsed.column)
              end
            end
          end
        end
      end
    end

    -- Mark this method as scanned for cache management
    cache.update_cache_timestamp(method)
  end

  -- Save cache to file after all methods are processed
  cache.save_to_file()
end

return M
