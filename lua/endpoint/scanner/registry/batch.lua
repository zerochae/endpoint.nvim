-- Batch scanner - Responsible for batch operations and actions
local base = require "endpoint.scanner.base"
local cache = require "endpoint.services.cache"
local framework = require "endpoint.services.framework"

local M = base.new {}

-- Process method for batch operations
function M:process(method, options)
  options = options or {}

  if options.operation == "scan_all" then
    return self:scan_all()
  elseif options.operation == "clear_cache" then
    return self:clear_cache()
  elseif options.operation == "get_cache_data" then
    return self:get_cache_data()
  else
    error("Unknown batch operation: " .. (options.operation or "nil"))
  end
end

-- Batch scan all HTTP methods efficiently
function M:scan_all()
  local framework, config = self:get_framework()
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
      local file_patterns = framework.get_file_patterns()
      local exclude_patterns = framework.get_exclude_patterns()

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
            if parsed and parsed.endpoint_path and parsed.endpoint_path ~= "" and parsed.endpoint_path:match "%S" then
              local endpoint_key = method .. " " .. parsed.endpoint_path

              if not processed_endpoints[endpoint_key] then
                processed_endpoints[endpoint_key] = true

                -- Store in cache
                cache.create_find_table_entry(parsed.file_path, method)
                cache.insert_to_find_table {
                  path = parsed.file_path,
                  annotation = parsed.method, -- Use framework-specific method
                  value = parsed.endpoint_path,
                  line_number = parsed.line_number,
                  column = parsed.column,
                }

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

-- Scan all method (maintains backward compatibility)
function M:scan_all_method()
  return self:process(nil, { operation = "scan_all" })
end

return M

