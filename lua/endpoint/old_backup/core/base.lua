local M = {}

---@generic T
---@param required_methods string[]
---@param optional_methods table<string, function>?
---@return T
function M.create_base(required_methods, optional_methods)
  local base = {}
  base.__index = base

  function base.new(implementation, name)
    implementation.name = name or "unknown"
    setmetatable(implementation, base)

    -- 필수 메서드 검증
    for _, method in ipairs(required_methods or {}) do
      if not implementation[method] or type(implementation[method]) ~= "function" then
        error(string.format("%s must implement method: %s", implementation.name, method))
      end
    end

    -- 선택적 메서드의 기본 구현 제공
    for method, default_impl in pairs(optional_methods or {}) do
      if not implementation[method] then
        implementation[method] = default_impl
      end
    end

    return implementation
  end

  function base:get_name()
    return self.name or "unknown"
  end

  function base:validate()
    return true
  end

  function base:get_type()
    return self.name
  end

  -- 공통 에러 처리
  function base:error(message)
    error(string.format("[%s] %s", self.name or "unknown", message))
  end

  -- 공통 로깅 (옵션)
  function base:log(message, level)
    level = level or vim.log.levels.INFO
    if self.debug then
      vim.notify(string.format("[%s] %s", self.name or "unknown", message), level)
    end
  end

  return base
end

-- 자주 사용되는 기본 메서드들
M.common_optional_methods = {
  is_available = function()
    return true
  end,
  get_default_config = function()
    return {}
  end,
  validate_options = function()
    return true
  end,
  cleanup = function() end,
}

return M
