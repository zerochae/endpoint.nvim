local M = {}

---Convert path parameters to unified format
---@param path string
---@param format? string Format template (default: "<param>")
---@return string
function M.format_params(path, format)
  format = format or "<%s>"

  if not path then
    return ""
  end

  -- Django path parameters: <type:name> -> <name>
  local formatted = path:gsub("<[^:>]*:([^>]+)>", function(name)
    return string.format(format, name)
  end)

  -- Django path parameters without type: <name> -> <name> (already formatted)
  -- Spring path variables: {name} -> <name>
  formatted = formatted:gsub("{([^}]+)}", function(name)
    return string.format(format, name)
  end)

  -- Express parameters: :name -> <name>
  formatted = formatted:gsub(":([%w_]+)", function(name)
    return string.format(format, name)
  end)

  return formatted
end

---Smart path normalization with parameter detection
---@param path string
---@return string
function M.normalize_smart(path)
  -- First normalize basic slashes
  path = path:gsub("//+", "/")

  -- Smart parameter conversion
  path = M.format_params(path)

  -- Remove query parameters and fragments
  path = path:gsub("%?.*$", "")
  path = path:gsub("#.*$", "")

  -- Resolve relative path components
  local parts = {}
  for part in path:gmatch("[^/]+") do
    if part == ".." then
      if #parts > 0 then
        table.remove(parts)
      end
    elseif part ~= "." and part ~= "" then
      table.insert(parts, part)
    end
  end

  local result = "/" .. table.concat(parts, "/")

  -- Ensure we don't end with / unless it's the root
  if result ~= "/" and result:match("/$") then
    result = result:sub(1, -2)
  end

  return result
end

---Extract parameters info from path
---@param path string
---@return table[]
function M.extract_params(path)
  local params = {}

  -- Extract different parameter formats
  for param in path:gmatch("<([^>]+)>") do
    table.insert(params, {
      name = param,
      type = "string",
      required = true
    })
  end

  -- Extract Django typed parameters
  for param_type, param_name in path:gmatch("<([^:>]*):([^>]+)>") do
    table.insert(params, {
      name = param_name,
      type = param_type,
      required = true
    })
  end

  -- Extract Spring/FastAPI parameters
  for param in path:gmatch("{([^}]+)}") do
    table.insert(params, {
      name = param,
      type = "string",
      required = true
    })
  end

  -- Extract Express parameters
  for param in path:gmatch(":([%w_]+)") do
    table.insert(params, {
      name = param,
      type = "string",
      required = true
    })
  end

  return params
end

---Join base path with relative path
---@param base string Base path
---@param rel string Relative path
---@return string
function M.join_with_base(base, rel)
  if not base or base == "" then
    return M.normalize_smart(rel)
  end

  if not rel or rel == "" then
    return M.normalize_smart(base)
  end

  -- Join and normalize
  local result
  if base:match("/$") and rel:match("^/") then
    result = base .. rel:sub(2)
  elseif not base:match("/$") and not rel:match("^/") then
    result = base .. "/" .. rel
  else
    result = base .. rel
  end

  return M.normalize_smart(result)
end

return M