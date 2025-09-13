---@class endpoint.frameworks.servlet
local M = {}

local fs = require "endpoint.utils.fs"

-- Detection
---@return boolean
function M.detect()
  -- For now, focus on pure servlet projects
  -- Multi-framework support will be implemented later as enhancement

  -- Check for traditional servlet indicators
  local has_servlet_indicators = fs.has_file { "web.xml", "WEB-INF/web.xml" }
  local has_webapp_structure = fs.has_file { "WEB-INF/", "src/main/webapp/" }

  -- Check for servlet annotations in Java files
  local has_servlet_annotations = false
  if fs.has_file { "src/" } then
    -- Quick check for @WebServlet usage
    local cmd = "find src -name '*.java' -exec grep -l '@WebServlet' {} \\; 2>/dev/null | head -1"
    local result = vim.fn.system(cmd)
    if vim.v.shell_error == 0 and result:match "%S" then
      has_servlet_annotations = true
    end
  end

  -- Check for servlet-api dependency without Spring
  local has_servlet_dependency = false
  if fs.has_file { "pom.xml" } then
    -- Check for servlet-api in Maven without Spring
    if fs.file_contains("pom.xml", "servlet-api") and not fs.file_contains("pom.xml", "spring-boot") then
      has_servlet_dependency = true
    end
  elseif fs.has_file { "build.gradle" } then
    -- Check for servlet-api in Gradle without Spring
    if fs.file_contains("build.gradle", "servlet-api") and not fs.file_contains("build.gradle", "spring-boot") then
      has_servlet_dependency = true
    end
  end

  return has_servlet_indicators or has_webapp_structure or has_servlet_annotations or has_servlet_dependency
end

-- Search command generation
---@param method string
---@return string
function M.get_search_cmd(method)
  -- Servlet patterns to search for
  local patterns = {
    GET = {
      "doGet", -- doGet method
    },
    POST = {
      "doPost", -- doPost method
    },
    PUT = {
      "doPut", -- doPut method
    },
    DELETE = {
      "doDelete", -- doDelete method
    },
    PATCH = {
      "doPatch", -- doPatch method
    },
    ALL = {
      "doGet",
      "doPost",
      "doPut",
      "doDelete",
      "doPatch",
    },
  }

  local method_patterns = patterns[method] or patterns.ALL

  local cmd = "rg --line-number --column --no-heading --color=never"
  cmd = cmd .. " --glob '**/*.java'"
  cmd = cmd .. " --glob '**/*.xml'"
  cmd = cmd .. " --glob '!**/target/**'"
  cmd = cmd .. " --glob '!**/build/**'"
  cmd = cmd .. " --glob '!**/.gradle/**'"

  -- Add patterns
  for _, pattern in ipairs(method_patterns) do
    cmd = cmd .. " -e '" .. pattern .. "'"
  end

  return cmd
end

-- Parse ripgrep output line
---@param line string
---@param method string
---@return table|nil
function M.parse_line(line, method)
  if not line or line == "" then
    return nil
  end

  -- Parse ripgrep output format: file:line:col:content
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path or not line_number or not column or not content then
    return nil
  end

  local servlet_method, servlet_path

  -- Pattern 1: doGet, doPost, etc. method signatures
  if not servlet_path then
    local do_method = content:match "(public%s+void%s+do%w+)" or content:match "(protected%s+void%s+do%w+)"
    if do_method then
      local method_name = do_method:match "do(%w+)"
      if method_name then
        servlet_method = method_name:upper()
        -- Try to find web.xml mapping or @WebServlet annotation for this servlet class
        local class_path = M.find_servlet_mapping_for_file(file_path)
        if not class_path then
          class_path = M.find_webservlet_annotation_for_file(file_path)
        end
        servlet_path = class_path or "/" -- Use web.xml mapping or @WebServlet if found, otherwise generic path
      end
    end
  end

  -- Pattern 3: servlet-class in web.xml
  if not servlet_path then
    local servlet_class = content:match "<servlet%-class>([^<]+)</servlet%-class>"
    if servlet_class then
      servlet_path = "/" .. servlet_class:match("([^.]+)$"):lower() -- Use class name as path
      servlet_method = "GET" -- Default method
    end
  end

  if not servlet_path then
    return nil
  end

  -- Clean up the path
  servlet_path = servlet_path:gsub("^%s+", ""):gsub("%s+$", "")

  -- Ensure path starts with /
  if not servlet_path:match "^/" and servlet_path ~= "*" then
    servlet_path = "/" .. servlet_path
  end

  return {
    method = servlet_method or method,
    endpoint_path = servlet_path,
    file_path = file_path,
    line_number = tonumber(line_number),
    column = tonumber(column),
  }
end

-- Find servlet mapping path for a Java servlet file
---@param java_file_path string
---@return string|nil
function M.find_servlet_mapping_for_file(java_file_path)
  -- Extract class name from file path
  local class_name = java_file_path:match "([^/]+)%.java$"
  if not class_name then
    return nil
  end

  -- Look for web.xml file
  local web_xml_paths = { "WEB-INF/web.xml", "web.xml", "src/main/webapp/WEB-INF/web.xml" }
  local web_xml_content = nil

  for _, web_xml_path in ipairs(web_xml_paths) do
    local file = io.open(web_xml_path, "r")
    if file then
      web_xml_content = file:read "*all"
      file:close()
      break
    end
  end

  if not web_xml_content then
    return nil
  end

  -- Find servlet-class that matches this file
  local servlet_name = nil
  for servlet_block in web_xml_content:gmatch "<servlet>(.-)</servlet>" do
    if servlet_block:match(class_name) then
      servlet_name = servlet_block:match "<servlet%-name>([^<]+)</servlet%-name>"
      break
    end
  end

  if not servlet_name then
    return nil
  end

  -- Find servlet-mapping for this servlet-name
  for mapping_block in web_xml_content:gmatch "<servlet%-mapping>(.-)</servlet%-mapping>" do
    if mapping_block:match("<servlet%-name>" .. servlet_name .. "</servlet%-name>") then
      local url_pattern = mapping_block:match "<url%-pattern>([^<]+)</url%-pattern>"
      if url_pattern then
        return url_pattern
      end
    end
  end

  return nil
end

-- Find @WebServlet annotation path for a Java servlet file
---@param java_file_path string
---@return string|nil
function M.find_webservlet_annotation_for_file(java_file_path)
  local file = io.open(java_file_path, "r")
  if not file then
    return nil
  end

  local content = file:read "*all"
  file:close()

  -- Look for @WebServlet annotation with urlPatterns
  local url_pattern = content:match '@WebServlet[^)]*urlPatterns[^=]*=[^"]*"([^"]+)"'
  if url_pattern then
    return url_pattern
  end

  -- Look for @WebServlet annotation with value attribute
  url_pattern = content:match '@WebServlet[^)]*value[^=]*=[^"]*"([^"]+)"'
  if url_pattern then
    return url_pattern
  end

  -- Look for @WebServlet simple form
  url_pattern = content:match '@WebServlet[^)]*"([^"]+)"'
  if url_pattern then
    return url_pattern
  end

  return nil
end

-- Check if a url-pattern line is within servlet-mapping context
---@param file_path string
---@param line_number number
---@return boolean
function M.is_servlet_mapping_pattern(file_path, line_number)
  local file = io.open(file_path, "r")
  if not file then
    return false
  end

  local lines = {}
  local current_line = 1
  for line in file:lines() do
    table.insert(lines, line)
    current_line = current_line + 1
  end
  file:close()

  -- Look backwards and forwards for servlet-mapping or filter-mapping context
  local start_line = math.max(1, line_number - 10)
  local end_line = math.min(#lines, line_number + 10)

  local in_servlet_mapping = false
  local in_filter_mapping = false

  for i = start_line, end_line do
    local line = lines[i]
    if line:match "<servlet%-mapping>" then
      in_servlet_mapping = true
    elseif line:match "</servlet%-mapping>" then
      in_servlet_mapping = false
    elseif line:match "<filter%-mapping>" then
      in_filter_mapping = true
    elseif line:match "</filter%-mapping>" then
      in_filter_mapping = false
    end

    -- If we're at the target line, check context
    if i == line_number then
      return in_servlet_mapping and not in_filter_mapping
    end
  end

  return false
end

return M
