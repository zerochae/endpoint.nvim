local fs = require "endpoint.utils.fs"
local log = require "endpoint.utils.log"

---@class endpoint.JavaConstantResolver
local M = {}

---@type table<string, table<string, string>>
local _cache = {}

---@type string|nil
local _cache_project_root = nil

local function _find_java_files(project_root)
  local cmd = string.format("find %s -name '*.java' -not -path '*/target/*' -not -path '*/build/*' -not -path '*/.gradle/*' 2>/dev/null", vim.fn.shellescape(project_root))
  local result = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return {}
  end
  return result
end

local function _parse_constants_from_file(file_path)
  local lines = fs.read_file(file_path)
  if not lines then
    return {}
  end

  local constants = {}

  local class_stack = {}
  local brace_depth = 0

  for _, line in ipairs(lines) do
    local stripped = line:match "^%s*//.*$" and "" or line

    local class_name = stripped:match "^%s*public%s+static%s+class%s+(%w+)"
      or stripped:match "^%s*public%s+static%s+interface%s+(%w+)"
      or stripped:match "^%s*static%s+class%s+(%w+)"
      or stripped:match "^%s*static%s+interface%s+(%w+)"

    if not class_name then
      class_name = stripped:match "^%s*public%s+class%s+(%w+)"
        or stripped:match "^%s*public%s+interface%s+(%w+)"
        or stripped:match "^%s*class%s+(%w+)"
        or stripped:match "^%s*interface%s+(%w+)"
    end

    for char in stripped:gmatch "." do
      if char == "{" then
        brace_depth = brace_depth + 1
        if class_name then
          table.insert(class_stack, { name = class_name, depth = brace_depth })
          class_name = nil
        end
      elseif char == "}" then
        if #class_stack > 0 and class_stack[#class_stack].depth == brace_depth then
          table.remove(class_stack)
        end
        brace_depth = brace_depth - 1
      end
    end

    local field_name, field_value = stripped:match '%s*public%s+static%s+final%s+String%s+([%w_]+)%s*=%s*"([^"]*)"'
    if not field_name then
      field_name, field_value = stripped:match '%s*static%s+final%s+String%s+([%w_]+)%s*=%s*"([^"]*)"'
    end
    if not field_name then
      field_name, field_value = stripped:match '%s*final%s+static%s+String%s+([%w_]+)%s*=%s*"([^"]*)"'
    end

    if field_name and field_value then
      local qualified_name = ""
      for _, entry in ipairs(class_stack) do
        qualified_name = qualified_name .. entry.name .. "."
      end
      qualified_name = qualified_name .. field_name
      constants[qualified_name] = field_value
    end
  end

  return constants
end

local function _build_constant_map(project_root)
  local java_files = _find_java_files(project_root)
  local constant_map = {}

  for _, file_path in ipairs(java_files) do
    local constants = _parse_constants_from_file(file_path)
    for qualified_name, value in pairs(constants) do
      constant_map[qualified_name] = value
    end
  end

  return constant_map
end

function M.resolve(constant_ref, project_root)
  project_root = project_root or fs.get_project_root()

  if _cache_project_root ~= project_root then
    _cache = {}
    _cache_project_root = project_root
  end

  if vim.tbl_isempty(_cache) then
    _cache = _build_constant_map(project_root)
    log.framework_debug("Java constant resolver: loaded " .. vim.tbl_count(_cache) .. " constants")
  end

  local value = _cache[constant_ref]
  if value then
    return value
  end

  for qualified_name, const_value in pairs(_cache) do
    if qualified_name:match("[^.]+%." .. vim.pesc(constant_ref) .. "$") then
      return const_value
    end
    if qualified_name:sub(-#constant_ref) == constant_ref then
      return const_value
    end
  end

  return nil
end

function M.resolve_from_file_context(constant_ref, file_path, project_root)
  project_root = project_root or fs.get_project_root()

  local direct = M.resolve(constant_ref, project_root)
  if direct then
    return direct
  end

  if not file_path then
    return nil
  end

  local lines = fs.read_file(file_path)
  if not lines then
    return nil
  end

  local ref_parts = vim.split(constant_ref, ".", { plain = true })
  local root_class = ref_parts[1]
  local sub_ref = table.concat(ref_parts, ".", 2)

  for _, line in ipairs(lines) do
    local imported_class = line:match("import%s+[%w%.]+%.(" .. root_class .. ")%s*;")
    if imported_class then
      local full_ref = imported_class .. "." .. sub_ref
      local resolved = M.resolve(full_ref, project_root)
      if resolved then
        return resolved
      end
    end

    local wildcard_package = line:match "import%s+([%w%.]+)%.%*%s*;"
    if wildcard_package then
      local resolved = M.resolve(constant_ref, project_root)
      if resolved then
        return resolved
      end
    end
  end

  return nil
end

function M.clear_cache()
  _cache = {}
  _cache_project_root = nil
end

function M.get_all_constants(project_root)
  project_root = project_root or fs.get_project_root()

  if _cache_project_root ~= project_root or vim.tbl_isempty(_cache) then
    _cache = _build_constant_map(project_root)
    _cache_project_root = project_root
  end

  return _cache
end

M._parse_constants_from_file = _parse_constants_from_file

return M
