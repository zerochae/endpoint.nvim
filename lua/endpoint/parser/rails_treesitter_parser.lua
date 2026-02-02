-- Tree-sitter based Rails endpoint parser
local TreeSitterParser = require "endpoint.core.TreeSitterParser"
local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"

---@class endpoint.RailsTreeSitterParser : endpoint.core.TreeSitterParser
local RailsTreeSitterParser = class("RailsTreeSitterParser", TreeSitterParser)

local METHOD_MAP = {
  get = "GET",
  post = "POST",
  put = "PUT",
  patch = "PATCH",
  delete = "DELETE",
  match = "ROUTE",
  root = "GET",
}

function RailsTreeSitterParser:initialize()
  TreeSitterParser.initialize(self, {
    parser_name = "rails_treesitter_parser",
    framework_name = "rails",
    language = "ruby",
  })
end

---Check if Tree-sitter Ruby parser is available
---@return boolean
function RailsTreeSitterParser:is_available()
  return self:is_treesitter_available("ruby")
end

---Extract endpoints from a Rails routes.rb file
---@param file_path string Path to the file
---@param options table|nil Options
---@return table[] endpoints
function RailsTreeSitterParser:extract_endpoints(file_path, options)
  options = options or {}
  local endpoints = {}

  if not self:is_available() then
    log.framework_debug "Tree-sitter Ruby parser not available"
    return endpoints
  end

  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return endpoints
  end
  local content = table.concat(lines, "\n")

  local parser_ok, parser = pcall(vim.treesitter.get_string_parser, content, "ruby")
  if not parser_ok or not parser then
    log.framework_debug "Failed to create Ruby parser"
    return endpoints
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return endpoints
  end

  local tree = trees[1]
  local root = tree:root()

  -- Find route definitions
  local route_endpoints = self:_find_routes(root, content, file_path, options)
  vim.list_extend(endpoints, route_endpoints)

  return endpoints
end

---Find Rails route definitions
---@param root userdata Tree-sitter root node
---@param content string File content
---@param file_path string File path
---@param options table Options
---@return table[] endpoints
function RailsTreeSitterParser:_find_routes(root, content, file_path, options)
  local endpoints = {}

  local query_string = [[
    (call
      method: (identifier) @method
      arguments: (argument_list
        [(string (string_content) @path) (simple_symbol) @symbol]
      )?
    ) @call
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, "ruby", query_string)
  if not query_ok or not query then
    log.framework_debug "Failed to parse Rails route query"
    return endpoints
  end

  local current_method = nil
  local current_path = nil

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]

    if name == "method" then
      current_method = vim.treesitter.get_node_text(node, content)
    elseif name == "path" then
      current_path = vim.treesitter.get_node_text(node, content)
    elseif name == "symbol" then
      -- Convert :symbol to /symbol
      local symbol = vim.treesitter.get_node_text(node, content)
      current_path = "/" .. symbol:gsub("^:", "")
    elseif name == "call" then
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
            tags = { "ruby", "rails", "treesitter" },
            metadata = {
              parser = self.parser_name,
              framework_version = "rails",
              language = "ruby",
              source = "treesitter",
            },
          })
        end
      end

      current_method = nil
      current_path = nil
    end
  end

  return endpoints
end

return RailsTreeSitterParser
