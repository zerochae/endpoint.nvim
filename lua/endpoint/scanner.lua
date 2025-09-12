-- Simplified Scanner Implementation (Function-based)
local cache = require "endpoint.cache"

local M = {}

-- Available frameworks
local frameworks = {
  spring = require "endpoint.frameworks.spring",
  fastapi = require "endpoint.frameworks.fastapi",
  nestjs = require "endpoint.frameworks.nestjs",
  symfony = require "endpoint.frameworks.symfony",
  rails = require "endpoint.frameworks.rails",
}

-- Main scan function
function M.scan(method, options)
  method = method or "ALL"
  options = options or {}

  -- Check cache first
  if not options.force_refresh and cache.is_valid(method) then
    local cached_results = cache.get_endpoints(method)
    if vim.g.endpoint_debug then
      vim.notify(
        string.format("🚀 Using cached data for %s: %d endpoints found", method, #cached_results),
        vim.log.levels.INFO
      )
    end
    return cached_results
  end

  if vim.g.endpoint_debug then
    vim.notify(string.format("🔍 Cache miss for %s, scanning filesystem...", method), vim.log.levels.INFO)
  end

  -- Detect framework
  local framework = M.detect_framework()
  if not framework then
    vim.notify("No supported framework detected", vim.log.levels.WARN)
    return {}
  end

  -- Execute search
  local cmd = framework.get_search_cmd(method)
  local output = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    if exit_code == 1 then
      return {} -- No results found
    else
      vim.notify("Search command failed: " .. cmd, vim.log.levels.ERROR)
      return {}
    end
  end

  -- Parse results
  local endpoints = {}
  for line in vim.gsplit(output, "\n") do
    if line ~= "" then
      local result = framework.parse_line(line, method)
      if result then
        -- Check if result is a single endpoint or array of endpoints
        if result.method then
          -- Single endpoint
          if result.endpoint_path and result.endpoint_path ~= "" then
            table.insert(endpoints, result)
            cache.save_endpoint(result.method, result)
          end
        else
          -- Array of endpoints (multiple methods)
          for _, endpoint in ipairs(result) do
            if endpoint.endpoint_path and endpoint.endpoint_path ~= "" then
              table.insert(endpoints, endpoint)
              cache.save_endpoint(endpoint.method, endpoint)
            end
          end
        end
      end
    end
  end

  -- Prepare preview data
  if #endpoints > 0 then
    M.prepare_preview(endpoints)
  end

  -- Save to file once after all endpoints are collected (for persistent mode)
  if cache.get_mode() == "persistent" and #endpoints > 0 then
    cache.save_to_file()
  end

  return endpoints
end

-- Framework detection
function M.detect_framework()
  for _, framework in pairs(frameworks) do
    if framework.detect() then
      return framework
    end
  end
  return nil
end

-- Prepare preview data for picker
function M.prepare_preview(endpoints)
  for _, endpoint in ipairs(endpoints) do
    local preview_key = endpoint.method .. " " .. endpoint.endpoint_path
    cache.save_preview(preview_key, endpoint.file_path, endpoint.line_number, endpoint.column)
  end
end

-- Get cached endpoints for a method
function M.get_cached_endpoints(method)
  return cache.get_endpoints(method)
end

-- Get preview data for an endpoint
function M.get_preview_data(endpoint_key)
  return cache.get_preview(endpoint_key)
end

-- Clear cache
function M.clear_cache()
  cache.clear()
end

-- Get cache statistics
function M.get_cache_stats()
  return cache.get_stats()
end

-- Initialize scanner with config
function M.setup(config)
  config = config or {}
  cache.set_mode(config.cache_mode or "session")
end

return M
