-- Tree-sitter based Servlet endpoint parser
local TreeSitterParser = require "endpoint.core.TreeSitterParser"
local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"

---@class endpoint.ServletTreeSitterParser : endpoint.core.TreeSitterParser
local ServletTreeSitterParser = class("ServletTreeSitterParser", TreeSitterParser)

-- Mapping doXxx method to HTTP method
local METHOD_MAP = {
  doGet = "GET",
  doPost = "POST",
  doPut = "PUT",
  doDelete = "DELETE",
  doPatch = "PATCH",
  doOptions = "OPTIONS",
  doHead = "HEAD",
}

function ServletTreeSitterParser:initialize()
  TreeSitterParser.initialize(self, {
    parser_name = "servlet_treesitter_parser",
    framework_name = "servlet",
    language = "java",
  })

  self._query = nil
  self._query_loaded = false
end

---Check if Tree-sitter Java parser is available
---@return boolean
function ServletTreeSitterParser:is_available()
  return self:is_treesitter_available("java")
end

---Extract endpoints from a Java Servlet file
---@param file_path string Path to the Java file
---@param options table|nil Options
---@return table[] endpoints
function ServletTreeSitterParser:extract_endpoints(file_path, options)
  options = options or {}
  local endpoints = {}

  if not self:is_available() then
    log.framework_debug "Tree-sitter Java parser not available"
    return endpoints
  end

  -- Read file content
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return endpoints
  end
  local content = table.concat(lines, "\n")

  -- Parse with Tree-sitter
  local parser_ok, parser = pcall(vim.treesitter.get_string_parser, content, "java")
  if not parser_ok or not parser then
    log.framework_debug "Failed to create Java parser"
    return endpoints
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return endpoints
  end

  local tree = trees[1]
  local root = tree:root()

  -- Find @WebServlet annotation paths
  local url_patterns = self:_find_webservlet_paths(root, content)

  -- Find all doXxx methods
  local method_endpoints = self:_find_do_methods(root, content, file_path, url_patterns, options)
  vim.list_extend(endpoints, method_endpoints)

  return endpoints
end

---Find @WebServlet annotation and extract URL patterns
---@param root userdata Tree-sitter root node
---@param content string File content
---@return string[] url_patterns
function ServletTreeSitterParser:_find_webservlet_paths(root, content)
  local paths = {}

  local query_string = [[
    (class_declaration
      (modifiers
        (annotation
          name: (identifier) @anno_name
          arguments: (annotation_argument_list)? @anno_args
        )
        (#eq? @anno_name "WebServlet")
      )
    )
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, "java", query_string)
  if not query_ok or not query then
    return paths
  end

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]
    if name == "anno_args" then
      local extracted = self:_extract_url_patterns(node, content)
      if extracted then
        vim.list_extend(paths, extracted)
      end
    end
  end

  return paths
end

---Extract URL patterns from annotation arguments
---@param args_node userdata Annotation arguments node
---@param content string File content
---@return string[]|nil patterns
function ServletTreeSitterParser:_extract_url_patterns(args_node, content)
  if not args_node then
    return nil
  end

  local patterns = {}

  for child in args_node:iter_children() do
    local child_type = child:type()

    if child_type == "string_literal" then
      -- Direct string: @WebServlet("/path")
      local text = vim.treesitter.get_node_text(child, content)
      table.insert(patterns, text:gsub('^"', ""):gsub('"$', ""))
    elseif child_type == "element_value_pair" then
      local key_node = child:field("key")[1]
      local value_node = child:field("value")[1]

      if key_node and value_node then
        local key = vim.treesitter.get_node_text(key_node, content)
        if key == "value" or key == "urlPatterns" then
          -- Could be single string or array
          local value_type = value_node:type()
          if value_type == "string_literal" then
            local text = vim.treesitter.get_node_text(value_node, content)
            table.insert(patterns, text:gsub('^"', ""):gsub('"$', ""))
          elseif value_type == "element_value_array_initializer" then
            -- Array of strings
            for array_child in value_node:iter_children() do
              if array_child:type() == "string_literal" then
                local text = vim.treesitter.get_node_text(array_child, content)
                table.insert(patterns, text:gsub('^"', ""):gsub('"$', ""))
              end
            end
          end
        end
      end
    end
  end

  return #patterns > 0 and patterns or nil
end

---Find doXxx method declarations
---@param root userdata Tree-sitter root node
---@param content string File content
---@param file_path string File path
---@param url_patterns string[] URL patterns from @WebServlet
---@param options table Options
---@return table[] endpoints
function ServletTreeSitterParser:_find_do_methods(root, content, file_path, url_patterns, options)
  local endpoints = {}

  local query_string = [[
    (method_declaration
      type: (void_type)
      name: (identifier) @method_name
      (#match? @method_name "^do(Get|Post|Put|Delete|Patch|Options|Head)$")
    ) @method
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, "java", query_string)
  if not query_ok or not query then
    log.framework_debug "Failed to parse servlet method query"
    return endpoints
  end

  local current_method_name = nil

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]

    if name == "method_name" then
      current_method_name = vim.treesitter.get_node_text(node, content)
    elseif name == "method" and current_method_name then
      local http_method = METHOD_MAP[current_method_name]
      if http_method then
        -- Apply method filter
        if not options.method or options.method == "" or http_method:upper() == options.method:upper() then
          local start_row = node:range()

          -- Create endpoint for each URL pattern
          local paths_to_use = #url_patterns > 0 and url_patterns or { "/" }
          for _, url_pattern in ipairs(paths_to_use) do
            table.insert(endpoints, {
              method = http_method,
              endpoint_path = url_pattern,
              file_path = file_path,
              line_number = start_row + 1,
              column = 1,
              display_value = http_method .. " " .. url_pattern,
              confidence = 0.95,
              tags = { "java", "servlet", "treesitter" },
              metadata = {
                parser = self.parser_name,
                framework_version = "servlet",
                language = "java",
                method_name = current_method_name,
                source = "treesitter",
              },
            })
          end
        end
      end
      current_method_name = nil
    end
  end

  return endpoints
end

return ServletTreeSitterParser
