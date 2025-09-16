-- Servlet Framework Utility Functions
---@class endpoint.frameworks.servlet.utils
local M = {}

-- Extract servlet path from doMethod or @WebServlet annotations
---@param content string
---@param file_path string
---@return string|nil
function M.extract_path(content, file_path)
  local servlet_path

  -- Pattern 1: doGet, doPost, etc. method signatures
  local do_method = content:match "(public%s+void%s+do%w+)" or content:match "(protected%s+void%s+do%w+)"
  if do_method then
    -- Try to find web.xml mapping or @WebServlet annotation for this servlet class
    local class_path = M.find_servlet_mapping_for_file(file_path)
    if not class_path then
      class_path = M.find_webservlet_annotation_for_file(file_path)
    end
    servlet_path = class_path or "/" -- Use web.xml mapping or @WebServlet if found, otherwise generic path
  end

  -- Pattern 2: servlet-class in web.xml
  if not servlet_path then
    local servlet_class = content:match "<servlet%-class>([^<]+)</servlet%-class>"
    if servlet_class then
      servlet_path = "/" .. servlet_class:match("([^.]+)$"):lower() -- Use class name as path
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

  return servlet_path
end

-- Extract HTTP method from servlet methods
---@param content string
---@return string|nil
function M.extract_method(content)
  local do_method = content:match "(public%s+void%s+do%w+)" or content:match "(protected%s+void%s+do%w+)"
  if do_method then
    local method_name = do_method:match "do(%w+)"
    if method_name then
      return method_name:upper()
    end
  end

  -- Default for servlet-class entries
  if content:match "<servlet%-class>" then
    return "GET" -- Default method
  end

  return nil
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