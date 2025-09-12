local cache = require "endpoint.services.cache"
local framework = require "endpoint.services.framework"
local state = require "endpoint.core.state"
local log = require "endpoint.utils.log"
local core_base = require "endpoint.core.base"

-- Required methods that scanner implementations must provide
local required_methods = {
  "process",
}

-- Create base class for scanner implementations
---@class endpoint.ScannerBaseImpl
---@field new fun(implementation: table, name: string): table
---@field execute_command fun(self: endpoint.ScannerBaseImpl, cmd: string): string?
---@field process fun(self: endpoint.ScannerBaseImpl, method: string, options?: table): any

---@type endpoint.ScannerBaseImpl
local M = core_base.create_base(required_methods)
function M:execute_command(cmd)
  log.info("Running command: " .. cmd)

  local output = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  log.info("Command exit_code: " .. exit_code .. ", output length: " .. string.len(output))

  if exit_code ~= 0 then
    if exit_code == 1 then
      return ""
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

function M:get_framework()
  local config = state.get_config()

  if not config then
    local ok, core = pcall(require, "endpoint.core")
    if ok and core.get_config then
      config = core.get_config()
    end
  end

  if not config then
    config = {
      cache_mode = "none",
      debug = false,
      framework = "auto",
      methods = { "GET", "POST", "PUT", "DELETE", "PATCH" },
      rg_additional_args = "",
      frameworks = {},
    }
  end

  local framework_name = framework.get_current_framework_name()
  if not framework_name then
    log.warn "No framework detected"
    return nil, nil
  end

  local fw, _, _ = framework.get_current_framework()
  return fw, config
end

function M:discover_endpoints(method)
  local framework, config = self:get_framework()
  if not framework then
    return {}
  end

  local command = framework:get_grep_cmd(method, config)
  local output = self:execute_command(command)

  if not output or output == "" then
    return {}
  end

  local endpoints = {}
  log.info("Processing grep results, lines found: " .. select(2, output:gsub("\n", "\n")) + 1)

  for line in vim.gsplit(output, "\n") do
    if line ~= "" then
      log.info("Processing ripgrep line: " .. line)
      local parsed = framework:parse_line(line, method)
      log.info("Parse result: " .. (parsed and vim.inspect(parsed) or "nil"))

      if parsed and parsed.endpoint_path and parsed.endpoint_path ~= "" and parsed.endpoint_path:match "%S" then
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

function M:save_to_cache(method, endpoints)
  for _, endpoint in ipairs(endpoints) do
    cache.create_find_table_entry(endpoint.file_path, method)
    cache.insert_to_find_table {
      path = endpoint.file_path,
      annotation = endpoint.method,
      value = endpoint.endpoint_path,
      line_number = endpoint.line_number,
      column = endpoint.column,
    }
  end
  cache.update_cache_timestamp(method)
  cache.save_to_file()
end

function M:get_cache_data()
  return {
    find_table = cache.get_find_table(),
    preview_table = cache.get_preview_table(),
  }
end

function M:clear_cache()
  cache.clear_tables()
end

-- Required methods are automatically validated by core_base

return M
