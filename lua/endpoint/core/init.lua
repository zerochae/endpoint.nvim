local M = {}

local default_config = require "endpoint.core.config"
local manager = require "endpoint.framework.manager"
local state = require "endpoint.core.state"
local picker = require "endpoint.services.picker"
local log = require "endpoint.utils.log"

M.config = vim.deepcopy(default_config)

function M.get_config()
  return M.config
end

local function show_picker(method, opts)
  opts = opts or {}
  return picker.show_picker(method, opts)
end

-- HTTP method handlers (generated programmatically)
local methods = { "GET", "POST", "PUT", "DELETE", "PATCH" }
for _, method in ipairs(methods) do
  local method_lower = method:lower()
  M["pick_" .. method_lower .. "_mapping"] = function(opts)
    show_picker(method, opts)
  end
end

function M.pick_all_endpoints(opts)
  show_picker("ALL", opts)
end

function M.setup(opts)
  opts = opts or {}

  -- Setup all registries first (with error handling for incomplete migration)
  local ok, registry_setup = pcall(require, "endpoint.core.registry_setup")
  if ok then
    pcall(registry_setup.setup_registries)
  end

  local frameworks_config = manager.build_frameworks_config()
  local config_with_frameworks = vim.tbl_deep_extend("force", {}, default_config, { frameworks = frameworks_config })
  M.config = vim.tbl_deep_extend("force", {}, config_with_frameworks, opts)

  state.set_config(M.config)
  state.mark_setup_complete()

  M.validate_config(opts)

  local picker_init_success = picker.initialize()
  if not picker_init_success then
    log.warn "Picker initialization failed, falling back to telescope"
  end

  if opts.cache_mode == "persistent" then
    require "endpoint.services.cache"
  end
end
function M.validate_config(opts)
  -- Cache validation
  if opts.cache_ttl and type(opts.cache_ttl) ~= "number" then
    vim.notify("Warning: cache_ttl must be a number", vim.log.levels.WARN)
  end

  if opts.cache_mode and not vim.tbl_contains({ "none", "session", "persistent" }, opts.cache_mode) then
    vim.notify("Warning: cache_mode must be 'none', 'session', or 'persistent'", vim.log.levels.WARN)
  end

  -- UI validation
  if opts.ui then
    if opts.ui.method_colors then
      for method, color in pairs(opts.ui.method_colors) do
        if type(color) ~= "string" then
          vim.notify("Warning: method color for " .. method .. " must be a string", vim.log.levels.WARN)
        end
      end
    end

    if opts.ui.show_icons ~= nil and type(opts.ui.show_icons) ~= "boolean" then
      vim.notify("Warning: show_icons must be a boolean", vim.log.levels.WARN)
    end

    if opts.ui.show_method ~= nil and type(opts.ui.show_method) ~= "boolean" then
      vim.notify("Warning: show_method must be a boolean", vim.log.levels.WARN)
    end
  end

  -- Framework validation
  if opts.framework and type(opts.framework) ~= "string" then
    vim.notify("Warning: framework must be a string", vim.log.levels.WARN)
  end

  if opts.framework_paths and type(opts.framework_paths) ~= "table" then
    vim.notify("Warning: framework_paths must be a table", vim.log.levels.WARN)
  end

  -- Validate supported frameworks
  local supported_frameworks = manager.get_available_frameworks()
  table.insert(supported_frameworks, "auto")

  if opts.framework and not vim.tbl_contains(supported_frameworks, opts.framework) then
    vim.notify(
      "Warning: Unsupported framework '"
        .. opts.framework
        .. "'. Supported: "
        .. table.concat(supported_frameworks, ", "),
      vim.log.levels.WARN
    )
  end

  -- Picker validation
  if opts.picker and type(opts.picker) ~= "string" then
    vim.notify("Warning: picker must be a string", vim.log.levels.WARN)
  end

  local detector = require "endpoint.services.detector"
  local supported_pickers = detector.get_supported_pickers()
  if opts.picker and not detector.is_valid_picker_name(opts.picker) then
    vim.notify(
      "Warning: Unsupported picker '"
        .. opts.picker
        .. "'. Supported: "
        .. table.concat(supported_pickers, ", ")
        .. " (will fallback to vim_ui_select if not available)",
      vim.log.levels.WARN
    )
  end

  if opts.picker_opts and type(opts.picker_opts) ~= "table" then
    vim.notify("Warning: picker_opts must be a table", vim.log.levels.WARN)
  end
end

return M
