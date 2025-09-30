local EventManager = require "endpoint.manager.EventManager"

local _instance = nil

local M = {}

function M.get_instance()
  if not _instance then
    _instance = EventManager:new()
  end
  return _instance
end

function M.reset_instance()
  _instance = nil
end

return M