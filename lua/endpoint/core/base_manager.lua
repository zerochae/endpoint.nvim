local M = {}

function M.create_manager(module_name, default_type)
  local manager = {
    module_name = module_name,
    registry = {},
    instances = {},
    default_type = default_type or "default",
  }

  function manager.register(type, module_path)
    if not type or not module_path then
      error("Both type and module_path are required for " .. manager.module_name)
    end
    manager.registry[type] = module_path
    manager.instances[type] = nil
  end

  function manager.get(type)
    type = type or manager.default_type

    if manager.is_registry_empty() then
      error(manager.module_name .. " registry is empty. Call setup() first.")
    end

    local module_path = manager.registry[type]
    if not module_path then
      local available = vim.tbl_keys(manager.registry)
      error(
        "Unknown " .. manager.module_name .. " type: " .. type .. ". Available types: " .. table.concat(available, ", ")
      )
    end

    if manager.instances[type] then
      return manager.instances[type]
    end

    local ok, impl = pcall(require, module_path)
    if not ok then
      error("Failed to load " .. manager.module_name .. " implementation: " .. type .. " (" .. impl .. ")")
    end

    manager.instances[type] = impl
    return impl
  end

  function manager.get_available_types()
    return vim.tbl_keys(manager.registry)
  end

  function manager.clear_cache()
    manager.instances = {}
  end

  function manager.has_type(type)
    return manager.registry[type] ~= nil
  end

  function manager.get_registry()
    return vim.deepcopy(manager.registry)
  end

  function manager.set_registry(registry_config)
    if not registry_config or type(registry_config) ~= "table" then
      error("Registry config must be a table for " .. manager.module_name)
    end

    manager.registry = vim.deepcopy(registry_config)
    manager.instances = {}
  end

  function manager.is_registry_empty()
    return next(manager.registry) == nil
  end

  return manager
end

return M

