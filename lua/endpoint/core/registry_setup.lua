local registry_config = require "endpoint.core.registry_config"
local log = require "endpoint.utils.log"

local M = {}

-- Registry of all managers that need to be configured
local managers = {
  framework = function()
    return require "endpoint.framework.manager"
  end,
  picker = function()
    return require "endpoint.picker.manager"
  end,
  cache = function()
    return require "endpoint.cache.manager"
  end,
  scanner = function()
    return require "endpoint.scanner.manager"
  end,
  detector = function()
    return require "endpoint.detector.manager"
  end,
}

function M.setup_registries()
  log.info "Setting up registries..."

  for manager_name, manager_loader in pairs(managers) do
    local manager = manager_loader()
    local config = registry_config[manager_name]

    if config then
      -- Check if manager has required methods
      if not manager.is_registry_empty then
        log.warn("Manager " .. manager_name .. " is missing is_registry_empty method")
      elseif not manager.set_registry then
        log.warn("Manager " .. manager_name .. " is missing set_registry method")
      elseif manager.is_registry_empty() then
        log.info("Registering " .. manager_name .. " implementations: " .. table.concat(vim.tbl_keys(config), ", "))
        manager.set_registry(config)
      else
        log.debug(manager_name .. " registry already configured")
      end
    else
      log.warn("No registry config found for " .. manager_name)
    end
  end

  log.info "Registry setup completed"
end

function M.clear_all_registries()
  log.info "Clearing all registries..."

  for manager_name, manager_loader in pairs(managers) do
    local manager = manager_loader()
    manager.set_registry {}
    log.debug("Cleared " .. manager_name .. " registry")
  end
end

function M.get_registry_status()
  local status = {}

  for manager_name, manager_loader in pairs(managers) do
    local manager = manager_loader()
    status[manager_name] = {
      types = manager.get_available_types(),
      count = #manager.get_available_types(),
      is_empty = manager.is_registry_empty(),
    }
  end

  return status
end

return M
