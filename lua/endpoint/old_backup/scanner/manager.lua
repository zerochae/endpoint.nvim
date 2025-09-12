local base_manager = require "endpoint.core.base_manager"

---@class endpoint.ScannerManagerImpl
---@field register fun(type: string, module_path: string)
---@field get fun(type?: string): any

---@type endpoint.ScannerManagerImpl
local M = base_manager.create_manager("scanner", "finder")

-- Scanner implementations will be registered during setup
-- Temporary fallback: register immediately for compatibility
M.register("finder", "endpoint.scanner.registry.finder")
M.register("previewer", "endpoint.scanner.registry.previewer")
M.register("batch", "endpoint.scanner.registry.batch")

-- Convenience methods for common scanner types
function M.finder()
  return M.get "finder"
end

function M.previewer()
  return M.get "previewer"
end

function M.batch()
  return M.get "batch"
end

return M
