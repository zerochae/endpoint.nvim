-- Tree-sitter based FastAPI endpoint parser
local TreeSitterParser = require "endpoint.core.TreeSitterParser"
local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"

---@class endpoint.FastApiTreeSitterParser : endpoint.core.TreeSitterParser
local FastApiTreeSitterParser = class("FastApiTreeSitterParser", TreeSitterParser)

local METHOD_MAP = {
  get = "GET",
  post = "POST",
  put = "PUT",
  delete = "DELETE",
  patch = "PATCH",
  options = "OPTIONS",
  head = "HEAD",
}

function FastApiTreeSitterParser:initialize()
  TreeSitterParser.initialize(self, {
    parser_name = "fastapi_treesitter_parser",
    framework_name = "fastapi",
    language = "python",
  })
end

---Check if Tree-sitter Python parser is available
---@return boolean
function FastApiTreeSitterParser:is_available()
  return self:is_treesitter_available("python")
end

---Extract endpoints from a Python FastAPI file
---@param file_path string Path to the file
---@param options table|nil Options
---@return table[] endpoints
function FastApiTreeSitterParser:extract_endpoints(file_path, options)
  options = options or {}
  local endpoints = {}

  if not self:is_available() then
    log.framework_debug "Tree-sitter Python parser not available"
    return endpoints
  end

  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return endpoints
  end
  local content = table.concat(lines, "\n")

  local parser_ok, parser = pcall(vim.treesitter.get_string_parser, content, "python")
  if not parser_ok or not parser then
    log.framework_debug "Failed to create Python parser"
    return endpoints
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return endpoints
  end

  local tree = trees[1]
  local root = tree:root()

  -- Find FastAPI route decorators
  local route_endpoints = self:_find_route_decorators(root, content, file_path, options)
  vim.list_extend(endpoints, route_endpoints)

  return endpoints
end

---Find FastAPI route decorators (@app.get, @router.post, etc.)
---@param root userdata Tree-sitter root node
---@param content string File content
---@param file_path string File path
---@param options table Options
---@return table[] endpoints
function FastApiTreeSitterParser:_find_route_decorators(root, content, file_path, options)
  local endpoints = {}

  local query_string = [[
    (decorated_definition
      (decorator
        (call
          function: (attribute
            object: (identifier) @object
            attribute: (identifier) @method
          )
          arguments: (argument_list
            (string (string_content) @path)?
          )
        )
      ) @decorator
      definition: (function_definition
        name: (identifier) @func_name
      )
    )
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, "python", query_string)
  if not query_ok or not query then
    log.framework_debug "Failed to parse FastAPI decorator query"
    return endpoints
  end

  local current_object = nil
  local current_method = nil
  local current_path = nil
  local current_func = nil

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]

    if name == "object" then
      current_object = vim.treesitter.get_node_text(node, content)
    elseif name == "method" then
      current_method = vim.treesitter.get_node_text(node, content)
    elseif name == "path" then
      current_path = vim.treesitter.get_node_text(node, content)
    elseif name == "func_name" then
      current_func = vim.treesitter.get_node_text(node, content)
    elseif name == "decorator" then
      -- Check if this is a FastAPI route
      if current_object and (current_object == "app" or current_object == "router") then
        if current_method and METHOD_MAP[current_method] then
          local http_method = METHOD_MAP[current_method]

          if not options.method or options.method == "" or http_method:upper() == options.method:upper() then
            local endpoint_path = current_path or "/"
            local start_row = node:range()

            table.insert(endpoints, {
              method = http_method,
              endpoint_path = endpoint_path,
              file_path = file_path,
              line_number = start_row + 1,
              column = 1,
              display_value = http_method .. " " .. endpoint_path,
              confidence = 0.95,
              tags = { "python", "fastapi", "treesitter" },
              metadata = {
                parser = self.parser_name,
                framework_version = "fastapi",
                language = "python",
                function_name = current_func,
                source = "treesitter",
              },
            })
          end
        end
      end

      current_object = nil
      current_method = nil
      current_path = nil
      current_func = nil
    end
  end

  return endpoints
end

return FastApiTreeSitterParser
