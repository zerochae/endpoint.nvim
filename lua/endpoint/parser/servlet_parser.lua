local Parser = require "endpoint.core.Parser"

---@class endpoint.ServletParser
local ServletParser = setmetatable({}, { __index = Parser })
ServletParser.__index = ServletParser

-- ========================================
-- PUBLIC METHODS
-- ========================================

---Creates a new ServletParser instance
function ServletParser:new()
  local servlet_parser = Parser:new {
    parser_name = "servlet_parser",
    framework_name = "servlet",
    language = "java",
  }
  setmetatable(servlet_parser, self)
  return servlet_parser
end

---Extracts base path from Servlet file
function ServletParser:extract_base_path(file_path, line_number)
  return ""  -- Servlets typically don't have base paths
end

---Extracts endpoint path from Servlet content
function ServletParser:extract_endpoint_path(content)
  -- Try to find @WebServlet annotation path
  local path = self:_extract_webservlet_path(content)
  if path then
    return path
  end

  return nil
end

---Extracts HTTP method from Servlet content
function ServletParser:extract_method(content)
  local method = self:_extract_servlet_method(content)
  if method then
    return method:upper()
  end

  return "GET" -- Default fallback
end

---Parses Servlet line and returns array of endpoints
function ServletParser:parse_line_to_endpoints(content, file_path, line_number, column)
  -- Only process if this looks like Servlet content
  if not self:is_content_valid_for_parsing(content) then
    return {}
  end

  local servlet_method = self:extract_method(content)
  if not servlet_method then
    return {}
  end

  -- Try to find servlet mapping for this file
  local servlet_path = self:_find_servlet_mapping_for_file(file_path)
  if not servlet_path then
    servlet_path = self:_find_webservlet_annotation_for_file(file_path)
  end

  -- If no mapping found, try to extract from XML context
  if not servlet_path and file_path:match "%.xml$" then
    servlet_path = self:_extract_servlet_class_path(content)
  end

  if not servlet_path then
    servlet_path = "/" -- Default fallback
  end

  -- Create single endpoint
  local endpoint = {
    method = servlet_method:upper(),
    endpoint_path = servlet_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = servlet_method:upper() .. " " .. servlet_path,
    confidence = self:get_parsing_confidence(content),
    tags = { "java", "servlet", "jee" },
    metadata = self:create_metadata("servlet", {
      servlet_type = self:_detect_servlet_type(content),
      has_webxml = self:_has_web_xml_mapping(file_path),
    }, content),
  }

  return { endpoint }
end

---Validates if content contains Servlet patterns
function ServletParser:is_content_valid_for_parsing(content)
  if not Parser.is_content_valid_for_parsing(self, content) then
    return false
  end

  -- Check if content contains Servlet patterns
  return self:_is_servlet_content(content)
end

---Gets parsing confidence for Servlet patterns
function ServletParser:get_parsing_confidence(content)
  if not self:is_content_valid_for_parsing(content) then
    return 0.0
  end

  local base_confidence = 0.8
  local confidence_boost = 0

  -- Boost for doXxx method patterns
  if content:match "do(Get|Post|Put|Delete|Patch)" then
    confidence_boost = confidence_boost + 0.1
  end

  -- Boost for @WebServlet annotation
  if content:match "@WebServlet" then
    confidence_boost = confidence_boost + 0.1
  end

  -- Boost for web.xml servlet mapping
  if content:match "<servlet%-class>" or content:match "<url%-pattern>" then
    confidence_boost = confidence_boost + 0.05
  end

  return math.min(base_confidence + confidence_boost, 1.0)
end

-- ========================================
-- PRIVATE METHODS
-- ========================================

---Checks if content looks like Servlet content
function ServletParser:_is_servlet_content(content)
  -- Check for Servlet method patterns
  return content:match "do(Get|Post|Put|Delete|Patch)"
    or content:match "@WebServlet"
    or content:match "<servlet%-class>"
    or content:match "<url%-pattern>"
end

---Extracts path from @WebServlet annotation
function ServletParser:_extract_webservlet_path(content)
  -- @WebServlet annotation with urlPatterns
  local path = content:match '@WebServlet[^)]*urlPatterns[^=]*=[^"]*"([^"]+)"'
  if path then
    return path
  end

  -- @WebServlet annotation with value attribute
  path = content:match '@WebServlet[^)]*value[^=]*=[^"]*"([^"]+)"'
  if path then
    return path
  end

  -- @WebServlet simple form
  path = content:match '@WebServlet[^)]*"([^"]+)"'
  if path then
    return path
  end

  return nil
end

---Extracts HTTP method from Servlet method names
function ServletParser:_extract_servlet_method(content)
  -- doGet, doPost, etc. method signatures
  local do_method = content:match "(public%s+void%s+do%w+)" or content:match "(protected%s+void%s+do%w+)"
  if do_method then
    local method_name = do_method:match "do(%w+)"
    if method_name then
      return method_name
    end
  end

  return nil
end

---Detects the type of Servlet implementation
function ServletParser:_detect_servlet_type(content)
  if content:match "@WebServlet" then
    return "annotation_based"
  elseif content:match "<servlet%-class>" then
    return "xml_based"
  elseif content:match "do(Get|Post|Put|Delete|Patch)" then
    return "method_based"
  else
    return "unknown"
  end
end

---Checks if file has web.xml mapping
function ServletParser:_has_web_xml_mapping(file_path)
  local web_xml_paths = { "WEB-INF/web.xml", "web.xml", "src/main/webapp/WEB-INF/web.xml" }
  for _, web_xml_path in ipairs(web_xml_paths) do
    local file = io.open(web_xml_path, "r")
    if file then
      file:close()
      return true
    end
  end
  return false
end

---Finds servlet mapping path for a Java servlet file
function ServletParser:_find_servlet_mapping_for_file(java_file_path)
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

---Finds @WebServlet annotation path for a Java servlet file
function ServletParser:_find_webservlet_annotation_for_file(java_file_path)
  local file = io.open(java_file_path, "r")
  if not file then
    return nil
  end

  local content = file:read "*all"
  file:close()

  return self:_extract_webservlet_path(content)
end

---Extracts servlet class path from XML content
function ServletParser:_extract_servlet_class_path(content)
  local servlet_class = content:match "<servlet%-class>([^<]+)</servlet%-class>"
  if servlet_class then
    -- Use class name as path
    return "/" .. servlet_class:match("([^.]+)$"):lower()
  end

  return nil
end

return ServletParser