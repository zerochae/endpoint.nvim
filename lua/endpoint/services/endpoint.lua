-- Endpoint search service
local framework_manager = require "endpoint.framework.manager"
local cache = require "endpoint.services.cache"

local M = {}

-- Run command and handle errors
function M.run_cmd(cmd)
  local output = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

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

-- Create endpoint table for a specific method
function M.create_endpoint_table(method, config)
  local grep_cmd = framework_manager.get_grep_cmd(method, config)
  if not grep_cmd then
    return {}
  end

  local output = M.run_cmd(grep_cmd)
  if not output or output == "" then
    return {}
  end

  local results = {}
  for line in output:gmatch "[^\r\n]+" do
    local parsed = framework_manager.parse_line(line, method, config)
    if parsed then
      table.insert(results, {
        value = method .. " " .. parsed.endpoint_path,
        method = parsed.method,
        path = parsed.endpoint_path,
        file_path = parsed.file_path,
        line_number = parsed.line_number,
      })
    end
  end

  return results
end

-- Get endpoints using cache
function M.get_endpoints(method, config)
  local cache_key = method

  -- Try to get from cache first
  local cached_results = cache.get_cached_results(cache_key, config)
  if cached_results then
    return cached_results
  end

  -- Generate new results
  local results = M.create_endpoint_table(method, config)

  -- Cache the results
  cache.set_cached_results(cache_key, results, config)

  return results
end

-- Clear all cached endpoints
function M.clear_cache()
  cache.clear_tables()
end

return M
