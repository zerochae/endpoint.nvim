-- Simplified Scanner Implementation
local cache = require "endpoint.cache"
local factory = require "endpoint.core.framework_factory"

local M = {}

-- Initialize framework factory
factory.load_all_frameworks()

-- Main scan function
---@param method? string
---@param options? table
---@return endpoint.entry[]
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
  local framework, framework_name = M.detect_framework()
  if not framework then
    vim.notify("No supported framework detected", vim.log.levels.WARN)
    return {}
  end

  -- Special handling for comprehensive analysis frameworks (Django, Rails, etc.)
  if factory.is_comprehensive_framework(framework) then
    if vim.g.endpoint_debug then
      vim.notify("[Scanner Debug] Using comprehensive analysis for method: " .. method, vim.log.levels.INFO)
    end

    -- Comprehensive frameworks perform full project analysis and then filter by method
    -- This ensures accuracy by parsing actual framework structure rather than pattern matching
    local comprehensive_endpoints = framework.get_all_endpoints_for_method(method)

    -- Save all discovered endpoints to cache (not just the filtered ones)
    if method == "ALL" then
      -- For ALL method, save all endpoints
      for _, endpoint in ipairs(comprehensive_endpoints) do
        cache.save_endpoint(endpoint.method, endpoint)
      end
    else
      -- For specific methods, we still need to get ALL endpoints to populate cache properly
      -- but only return the filtered ones
      local all_comprehensive_endpoints = framework.get_all_endpoints_for_method("ALL")
      for _, endpoint in ipairs(all_comprehensive_endpoints) do
        cache.save_endpoint(endpoint.method, endpoint)
      end
    end

    if vim.g.endpoint_debug then
      vim.notify(
        string.format("🔍 Comprehensive analysis for %s: %d endpoints found", method, #comprehensive_endpoints),
        vim.log.levels.INFO
      )
    end

    return comprehensive_endpoints
  end

  -- Execute search
  local cmd = framework.get_search_cmd(method)
  if vim.g.endpoint_debug then
    vim.notify("[Scanner Debug] Executing command: " .. cmd, vim.log.levels.INFO)
  end

  local output = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if vim.g.endpoint_debug then
    vim.notify(string.format("[Scanner Debug] Command exit code: %d", exit_code), vim.log.levels.INFO)
    vim.notify(string.format("[Scanner Debug] Raw output length: %d", string.len(output)), vim.log.levels.INFO)
    if string.len(output) > 0 then
      vim.notify("[Scanner Debug] Output preview: " .. output:sub(1, 300), vim.log.levels.INFO)
    end
  end

  if exit_code ~= 0 then
    if exit_code == 1 then
      if vim.g.endpoint_debug then
        vim.notify("[Scanner Debug] No results found (exit code 1)", vim.log.levels.WARN)
      end
      return {} -- No results found
    else
      vim.notify("Search command failed: " .. cmd, vim.log.levels.ERROR)
      return {}
    end
  end

  -- Parse results
  local endpoints = {}
  local line_count = 0
  for line in vim.gsplit(output, "\n") do
    line_count = line_count + 1
    if line ~= "" then
      if vim.g.endpoint_debug then
        vim.notify(string.format("[Scanner Debug] Processing line %d: %s", line_count, line), vim.log.levels.INFO)
      end
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

-- Framework detection using factory
---@return endpoint.framework?, string?
function M.detect_framework()
  if vim.g.endpoint_debug then
    vim.notify("[Scanner Debug] Starting framework detection...", vim.log.levels.INFO)
  end

  local framework, framework_name = factory.detect_framework()

  if vim.g.endpoint_debug then
    if framework_name then
      local analysis_type = factory.is_comprehensive_framework(framework) and "comprehensive" or "pattern-matching"
      vim.notify(string.format("[Scanner Debug] Detected framework: %s (type: %s)",
        framework_name, analysis_type), vim.log.levels.INFO)
    else
      vim.notify("[Scanner Debug] No framework detected", vim.log.levels.WARN)
    end
  end

  return framework, framework_name
end

-- Prepare preview data for picker
---@param endpoints endpoint.entry[]
function M.prepare_preview(endpoints)
  for _, endpoint in ipairs(endpoints) do
    local preview_key = endpoint.method .. " " .. endpoint.endpoint_path
    cache.save_preview(preview_key, endpoint.file_path, endpoint.line_number, endpoint.column)
  end
end

-- Get cached endpoints for a method
---@param method string
---@return endpoint.entry[]
function M.get_cached_endpoints(method)
  return cache.get_endpoints(method)
end

-- Get preview data for an endpoint
---@param endpoint_key string
---@return endpoint.cache.preview?
function M.get_preview_data(endpoint_key)
  return cache.get_preview(endpoint_key)
end

-- Clear cache
function M.clear_cache()
  cache.clear()
end

-- Get cache statistics
---@return endpoint.cache.stats
function M.get_cache_stats()
  return cache.get_stats()
end

-- Initialize scanner with config
---@param config table
function M.setup(config)
  config = config or {}
  cache.set_mode(config.cache_mode or "session")
end

return M
