-- Symfony framework implementation
local base = require "endpoint.framework.base"
local symfony_config = require "endpoint.framework.config.symfony"


-- Extract path from Symfony Route attribute/annotation
local function extract_path_from_route(s)
  if not s or s == "" then
    return ""
  end

  -- Extract path from Route attribute/annotation
  -- Patterns to match: #[Route('/path')] or @Route("/path")
  local path = s:match("#%[Route%(['\"](.-)['\"]") or s:match("@Route%(['\"](.-)['\"]")

  return path or ""
end

local function find_enclosing_class_decl_index(lines, start_line)
  for i = start_line, 1, -1 do
    local L = lines[i] or ""
    -- Look for actual class declaration (not ::class references)
    if L:match "^%s*final%s+class%s+" or L:match "^%s*abstract%s+class%s+" or L:match "^%s*class%s+" then
      return i
    end
    -- Stop at namespace declaration
    if L:match "^namespace%s+" then
      break
    end
  end
  return nil
end


-- =========================
-- Implementation
-- =========================
local M = base.new {}

function M:get_patterns(method)
  return symfony_config.patterns[method:lower()] or {}
end

function M:get_file_patterns()
  return symfony_config.file_patterns
end

function M:get_exclude_patterns()
  return symfony_config.exclude_patterns
end

-- Extract method-level route mapping
function M:_extract_method_mapping(file_path, line_number)
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return ""
  end

  local line = lines[line_number] or ""

  -- Check if current line contains Route attribute/annotation
  if not line:match "#%[Route" and not line:match "@Route" then
    -- Check lines above for annotation (within 5 lines)
    for j = math.max(1, line_number - 5), line_number - 1 do
      local prev_line = lines[j] or ""
      if prev_line:match "#%[Route" or prev_line:match "@Route" then
        line = prev_line
        break
      end
    end
  end

  return extract_path_from_route(line)
end

-- Extract class-level Route prefix
function M:get_base_path(file_path, line_number)
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return ""
  end

  -- Find the class declaration containing this method
  local class_decl_idx = find_enclosing_class_decl_index(lines, line_number)
  if not class_decl_idx then
    return ""
  end

  -- Simple approach: find Route between last 'use' statement and class declaration
  local base_path_patterns = symfony_config.base_path_patterns or {}
  local last_use_idx = 1

  -- Find the last 'use' statement before class declaration
  for i = 1, class_decl_idx - 1 do
    local line = lines[i] or ""
    if line:match("^use%s+") then
      last_use_idx = i
    end
  end

  -- Look for Route attributes between last use and class declaration
  for i = last_use_idx + 1, class_decl_idx - 1 do
    local line = lines[i] or ""

    if line:match("#%[Route") or line:match("@Route") then
      for _, pattern in ipairs(base_path_patterns) do
        local path = line:match(pattern)
        if path and path ~= "" then
          return path
        end
      end

      -- Fallback to extract_path_from_route function
      local extracted_path = extract_path_from_route(line)
      if extracted_path and extracted_path ~= "" then
        return extracted_path
      end
    end
  end

  return ""
end

-- Generate ripgrep command for finding endpoints
function M:get_grep_cmd(method, config)
  local patterns = self:get_patterns(method)
  if not patterns or #patterns == 0 then
    error("No patterns defined for method: " .. method)
  end

  local file_patterns = self:get_file_patterns()
  local exclude_patterns = self:get_exclude_patterns()

  local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"

  for _, pattern in ipairs(file_patterns) do
    cmd = cmd .. " --glob '" .. pattern .. "'"
  end

  for _, ex in ipairs(exclude_patterns) do
    cmd = cmd .. " --glob '!" .. ex .. "'"
  end
  if config and config.rg_additional_args and config.rg_additional_args ~= "" then
    cmd = cmd .. " " .. config.rg_additional_args
  end

  -- Use first pattern for initial search
  cmd = cmd .. " '" .. patterns[1] .. "'"
  return cmd
end

-- Parse ripgrep output line "path:line:col:content"
function M:parse_line(line, method)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    return nil
  end

  line_number = tonumber(line_number) or 1
  column = tonumber(column) or 1

  local endpoint_path = self:_extract_method_mapping(file_path, line_number)
  local base_path = self:get_base_path(file_path, line_number)
  local full_path = self:combine_paths(base_path, endpoint_path)

  return {
    file_path = file_path,
    line_number = line_number,
    column = column,
    endpoint_path = full_path,
    method = method:upper(),
    raw_line = line,
    content = content,
  }
end

return M

