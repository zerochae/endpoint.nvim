-- Tree-sitter based Symfony endpoint parser
local TreeSitterParser = require "endpoint.core.TreeSitterParser"
local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"

---@class endpoint.SymfonyTreeSitterParser : endpoint.core.TreeSitterParser
local SymfonyTreeSitterParser = class("SymfonyTreeSitterParser", TreeSitterParser)

local ATTRIBUTE_TO_METHOD = {
  Route = "ROUTE",
  Get = "GET",
  Post = "POST",
  Put = "PUT",
  Delete = "DELETE",
  Patch = "PATCH",
}

function SymfonyTreeSitterParser:initialize()
  TreeSitterParser.initialize(self, {
    parser_name = "symfony_treesitter_parser",
    framework_name = "symfony",
    language = "php",
  })
end

---Check if Tree-sitter PHP parser is available
---@return boolean
function SymfonyTreeSitterParser:is_available()
  return self:is_treesitter_available("php")
end

---Extract endpoints from a Symfony controller file
---@param file_path string Path to the file
---@param options table|nil Options
---@return table[] endpoints
function SymfonyTreeSitterParser:extract_endpoints(file_path, options)
  options = options or {}
  local endpoints = {}

  if not self:is_available() then
    log.framework_debug "Tree-sitter PHP parser not available"
    return endpoints
  end

  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return endpoints
  end
  local content = table.concat(lines, "\n")

  local parser_ok, parser = pcall(vim.treesitter.get_string_parser, content, "php")
  if not parser_ok or not parser then
    log.framework_debug "Failed to create PHP parser"
    return endpoints
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return endpoints
  end

  local tree = trees[1]
  local root = tree:root()

  -- Find Route attributes
  local route_endpoints = self:_find_route_attributes(root, content, file_path, options)
  vim.list_extend(endpoints, route_endpoints)

  return endpoints
end

---Find Symfony #[Route] attributes
---@param root userdata Tree-sitter root node
---@param content string File content
---@param file_path string File path
---@param options table Options
---@return table[] endpoints
function SymfonyTreeSitterParser:_find_route_attributes(root, content, file_path, options)
  local endpoints = {}

  local query_string = [[
    (attribute_group
      (attribute
        name: (name) @attr_name
        arguments: (arguments
          (argument
            (string (string_value) @path)?
          )
        )?
      ) @attr
    )
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, "php", query_string)
  if not query_ok or not query then
    log.framework_debug "Failed to parse Symfony route query"
    return endpoints
  end

  local current_attr_name = nil
  local current_path = nil

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]

    if name == "attr_name" then
      current_attr_name = vim.treesitter.get_node_text(node, content)
    elseif name == "path" then
      current_path = vim.treesitter.get_node_text(node, content)
    elseif name == "attr" then
      if current_attr_name and ATTRIBUTE_TO_METHOD[current_attr_name] then
        local http_method = ATTRIBUTE_TO_METHOD[current_attr_name]

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
            tags = { "php", "symfony", "treesitter" },
            metadata = {
              parser = self.parser_name,
              framework_version = "symfony",
              language = "php",
              source = "treesitter",
            },
          })
        end
      end

      current_attr_name = nil
      current_path = nil
    end
  end

  return endpoints
end

return SymfonyTreeSitterParser
