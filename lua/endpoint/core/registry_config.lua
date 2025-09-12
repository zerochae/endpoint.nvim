-- Registry configurations for all managers
local M = {}

M.framework = {
  spring = "endpoint.framework.registry.spring",
  nestjs = "endpoint.framework.registry.nestjs",
  fastapi = "endpoint.framework.registry.fastapi",
  symfony = "endpoint.framework.registry.symfony",
}

M.picker = {
  telescope = "endpoint.picker.registry.telescope",
  vim_ui_select = "endpoint.picker.registry.vim_ui_select",
  snacks = "endpoint.picker.registry.snacks",
}

M.cache = {
  none = "endpoint.cache.registry.none",
  session = "endpoint.cache.registry.session",
  persistent = "endpoint.cache.registry.persistent",
}

M.scanner = {
  finder = "endpoint.scanner.registry.finder",
  previewer = "endpoint.scanner.registry.previewer",
  batch = "endpoint.scanner.registry.batch",
}

M.detector = {
  framework = "endpoint.detector.registry.framework",
  picker = "endpoint.detector.registry.picker",
}

return M

