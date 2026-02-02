-- Tree-sitter based .NET endpoint parser
local TreeSitterParser = require "endpoint.core.TreeSitterParser"
local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"

---@class endpoint.DotnetTreeSitterParser : endpoint.core.TreeSitterParser
local DotnetTreeSitterParser = class("DotnetTreeSitterParser", TreeSitterParser)

local ATTRIBUTE_TO_METHOD = {
  HttpGet = "GET",
  HttpPost = "POST",
  HttpPut = "PUT",
  HttpDelete = "DELETE",
  HttpPatch = "PATCH",
  Route = "ROUTE",
}

function DotnetTreeSitterParser:initialize()
  TreeSitterParser.initialize(self, {
    parser_name = "dotnet_treesitter_parser",
    framework_name = "dotnet",
    language = "c_sharp",
  })
end

---Check if Tree-sitter C# parser is available
---@return boolean
function DotnetTreeSitterParser:is_available()
  return self:is_treesitter_available("c_sharp")
end

---Extract endpoints from a .NET controller file
---@param file_path string Path to the file
---@param options table|nil Options
---@return table[] endpoints
function DotnetTreeSitterParser:extract_endpoints(file_path, options)
  options = options or {}
  local endpoints = {}

  if not self:is_available() then
    log.framework_debug "Tree-sitter C# parser not available"
    return endpoints
  end

  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return endpoints
  end
  local content = table.concat(lines, "\n")

  local parser_ok, parser = pcall(vim.treesitter.get_string_parser, content, "c_sharp")
  if not parser_ok or not parser then
    log.framework_debug "Failed to create C# parser"
    return endpoints
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return endpoints
  end

  local tree = trees[1]
  local root = tree:root()

  -- Find controller base route
  local base_path = self:_find_controller_route(root, content)

  -- Find HTTP attribute decorators
  local route_endpoints = self:_find_http_attributes(root, content, file_path, base_path, options)
  vim.list_extend(endpoints, route_endpoints)

  return endpoints
end

---Find [Route] attribute on controller
---@param root userdata Tree-sitter root node
---@param content string File content
---@return string base_path
function DotnetTreeSitterParser:_find_controller_route(root, content)
  local query_string = [[
    (class_declaration
      (attribute_list
        (attribute
          name: (identifier) @attr_name
          (attribute_argument_list
            (attribute_argument
              (string_literal) @path
            )
          )?
          (#eq? @attr_name "Route")
        )
      )
    )
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, "c_sharp", query_string)
  if not query_ok or not query then
    return ""
  end

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]
    if name == "path" then
      local path = vim.treesitter.get_node_text(node, content)
      return path:gsub('^"', ""):gsub('"$', "")
    end
  end

  return ""
end

---Find [HttpGet], [HttpPost], etc. attributes
---@param root userdata Tree-sitter root node
---@param content string File content
---@param file_path string File path
---@param base_path string Controller base path
---@param options table Options
---@return table[] endpoints
function DotnetTreeSitterParser:_find_http_attributes(root, content, file_path, base_path, options)
  local endpoints = {}

  local query_string = [[
    (method_declaration
      (attribute_list
        (attribute
          name: (identifier) @attr_name
          (attribute_argument_list
            (attribute_argument
              (string_literal) @path
            )
          )?
        ) @attr
      )
      name: (identifier) @method_name
    ) @method
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, "c_sharp", query_string)
  if not query_ok or not query then
    log.framework_debug "Failed to parse .NET attribute query"
    return endpoints
  end

  local current_attr_name = nil
  local current_path = nil
  local current_method_name = nil

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]

    if name == "attr_name" then
      current_attr_name = vim.treesitter.get_node_text(node, content)
    elseif name == "path" then
      local path = vim.treesitter.get_node_text(node, content)
      current_path = path:gsub('^"', ""):gsub('"$', "")
    elseif name == "method_name" then
      current_method_name = vim.treesitter.get_node_text(node, content)
    elseif name == "method" then
      if current_attr_name and ATTRIBUTE_TO_METHOD[current_attr_name] then
        local http_method = ATTRIBUTE_TO_METHOD[current_attr_name]

        if not options.method or options.method == "" or http_method:upper() == options.method:upper() then
          local endpoint_path = self:_combine_paths(base_path, current_path or "")
          local start_row = node:range()

          table.insert(endpoints, {
            method = http_method,
            endpoint_path = endpoint_path,
            file_path = file_path,
            line_number = start_row + 1,
            column = 1,
            display_value = http_method .. " " .. endpoint_path,
            confidence = 0.95,
            tags = { "csharp", "dotnet", "treesitter" },
            metadata = {
              parser = self.parser_name,
              framework_version = "dotnet",
              language = "c_sharp",
              method_name = current_method_name,
              source = "treesitter",
            },
          })
        end
      end

      current_attr_name = nil
      current_path = nil
      current_method_name = nil
    end
  end

  return endpoints
end

---Combine base path and endpoint path
---@param base_path string
---@param endpoint_path string
---@return string
function DotnetTreeSitterParser:_combine_paths(base_path, endpoint_path)
  if not base_path or base_path == "" then
    return endpoint_path ~= "" and endpoint_path or "/"
  end
  if not endpoint_path or endpoint_path == "" then
    return base_path
  end

  local clean_base = base_path:gsub("/$", "")
  local clean_endpoint = endpoint_path:gsub("^/", "")

  return clean_base .. "/" .. clean_endpoint
end

return DotnetTreeSitterParser
