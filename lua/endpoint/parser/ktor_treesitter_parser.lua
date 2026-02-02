-- Tree-sitter based Ktor endpoint parser
local TreeSitterParser = require "endpoint.core.TreeSitterParser"
local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"

---@class endpoint.KtorTreeSitterParser : endpoint.core.TreeSitterParser
local KtorTreeSitterParser = class("KtorTreeSitterParser", TreeSitterParser)

local METHOD_MAP = {
  get = "GET",
  post = "POST",
  put = "PUT",
  delete = "DELETE",
  patch = "PATCH",
  head = "HEAD",
  options = "OPTIONS",
  route = "ROUTE",
}

function KtorTreeSitterParser:initialize()
  TreeSitterParser.initialize(self, {
    parser_name = "ktor_treesitter_parser",
    framework_name = "ktor",
    language = "kotlin",
  })
end

---Check if Tree-sitter Kotlin parser is available
---@return boolean
function KtorTreeSitterParser:is_available()
  return self:is_treesitter_available("kotlin")
end

---Extract endpoints from a Ktor routing file
---@param file_path string Path to the file
---@param options table|nil Options
---@return table[] endpoints
function KtorTreeSitterParser:extract_endpoints(file_path, options)
  options = options or {}
  local endpoints = {}

  if not self:is_available() then
    log.framework_debug "Tree-sitter Kotlin parser not available"
    return endpoints
  end

  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return endpoints
  end
  local content = table.concat(lines, "\n")

  local parser_ok, parser = pcall(vim.treesitter.get_string_parser, content, "kotlin")
  if not parser_ok or not parser then
    log.framework_debug "Failed to create Kotlin parser"
    return endpoints
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return endpoints
  end

  local tree = trees[1]
  local root = tree:root()

  -- Find Ktor route definitions
  local route_endpoints = self:_find_routes(root, content, file_path, options)
  vim.list_extend(endpoints, route_endpoints)

  return endpoints
end

---Find Ktor route definitions
---@param root userdata Tree-sitter root node
---@param content string File content
---@param file_path string File path
---@param options table Options
---@return table[] endpoints
function KtorTreeSitterParser:_find_routes(root, content, file_path, options)
  local endpoints = {}

  local query_string = [[
    (call_expression
      (simple_identifier) @method
      (call_suffix
        (value_arguments
          (value_argument
            (string_literal) @path
          )?
        )
      )
    ) @call
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, "kotlin", query_string)
  if not query_ok or not query then
    log.framework_debug "Failed to parse Ktor route query"
    return endpoints
  end

  local current_method = nil
  local current_path = nil

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]

    if name == "method" then
      current_method = vim.treesitter.get_node_text(node, content)
    elseif name == "path" then
      local path_text = vim.treesitter.get_node_text(node, content)
      current_path = path_text:gsub('^"', ""):gsub('"$', "")
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
            tags = { "kotlin", "ktor", "treesitter" },
            metadata = {
              parser = self.parser_name,
              framework_version = "ktor",
              language = "kotlin",
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

return KtorTreeSitterParser
