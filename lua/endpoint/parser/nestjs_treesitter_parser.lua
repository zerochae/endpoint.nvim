-- Tree-sitter based NestJS endpoint parser
local TreeSitterParser = require "endpoint.core.TreeSitterParser"
local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"

---@class endpoint.NestJsTreeSitterParser : endpoint.core.TreeSitterParser
local NestJsTreeSitterParser = class("NestJsTreeSitterParser", TreeSitterParser)

local DECORATOR_TO_METHOD = {
  Get = "GET",
  Post = "POST",
  Put = "PUT",
  Delete = "DELETE",
  Patch = "PATCH",
  All = "ALL",
  Options = "OPTIONS",
  Head = "HEAD",
}

function NestJsTreeSitterParser:initialize()
  TreeSitterParser.initialize(self, {
    parser_name = "nestjs_treesitter_parser",
    framework_name = "nestjs",
    language = "typescript",
  })
end

---Check if Tree-sitter TypeScript parser is available
---@return boolean
function NestJsTreeSitterParser:is_available()
  return self:is_treesitter_available("typescript")
end

---Extract endpoints from a TypeScript NestJS file
---@param file_path string Path to the file
---@param options table|nil Options
---@return table[] endpoints
function NestJsTreeSitterParser:extract_endpoints(file_path, options)
  options = options or {}
  local endpoints = {}

  if not self:is_available() then
    log.framework_debug "Tree-sitter TypeScript parser not available"
    return endpoints
  end

  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return endpoints
  end
  local content = table.concat(lines, "\n")

  local parser_ok, parser = pcall(vim.treesitter.get_string_parser, content, "typescript")
  if not parser_ok or not parser then
    log.framework_debug "Failed to create TypeScript parser"
    return endpoints
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return endpoints
  end

  local tree = trees[1]
  local root = tree:root()

  -- Find controller base path
  local base_path = self:_find_controller_path(root, content)

  -- Find route decorators
  local route_endpoints = self:_find_route_decorators(root, content, file_path, base_path, options)
  vim.list_extend(endpoints, route_endpoints)

  return endpoints
end

---Find @Controller decorator path
---@param root userdata Tree-sitter root node
---@param content string File content
---@return string base_path
function NestJsTreeSitterParser:_find_controller_path(root, content)
  local query_string = [[
    (decorator
      (call_expression
        function: (identifier) @name
        arguments: (arguments
          (string (string_fragment) @path)?
        )
        (#eq? @name "Controller")
      )
    )
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, "typescript", query_string)
  if not query_ok or not query then
    return ""
  end

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]
    if name == "path" then
      return vim.treesitter.get_node_text(node, content)
    end
  end

  return ""
end

---Find route decorators (@Get, @Post, etc.)
---@param root userdata Tree-sitter root node
---@param content string File content
---@param file_path string File path
---@param base_path string Controller base path
---@param options table Options
---@return table[] endpoints
function NestJsTreeSitterParser:_find_route_decorators(root, content, file_path, base_path, options)
  local endpoints = {}

  local query_string = [[
    (decorator
      (call_expression
        function: (identifier) @decorator_name
        arguments: (arguments
          (string (string_fragment) @path)?
        )?
      )
    ) @decorator
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, "typescript", query_string)
  if not query_ok or not query then
    log.framework_debug "Failed to parse NestJS decorator query"
    return endpoints
  end

  local current_decorator_name = nil
  local current_path = nil

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]

    if name == "decorator_name" then
      current_decorator_name = vim.treesitter.get_node_text(node, content)
    elseif name == "path" then
      current_path = vim.treesitter.get_node_text(node, content)
    elseif name == "decorator" then
      if current_decorator_name and DECORATOR_TO_METHOD[current_decorator_name] then
        local http_method = DECORATOR_TO_METHOD[current_decorator_name]

        if not options.method or options.method == "" or http_method:upper() == options.method:upper() then
          local endpoint_path = current_path or ""
          local full_path = self:_combine_paths(base_path, endpoint_path)
          local start_row = node:range()

          table.insert(endpoints, {
            method = http_method,
            endpoint_path = full_path,
            file_path = file_path,
            line_number = start_row + 1,
            column = 1,
            display_value = http_method .. " " .. full_path,
            confidence = 0.95,
            tags = { "typescript", "nestjs", "treesitter" },
            metadata = {
              parser = self.parser_name,
              framework_version = "nestjs",
              language = "typescript",
              decorator = current_decorator_name,
              source = "treesitter",
            },
          })
        end
      end

      current_decorator_name = nil
      current_path = nil
    end
  end

  return endpoints
end

---Combine base path and endpoint path
---@param base_path string
---@param endpoint_path string
---@return string
function NestJsTreeSitterParser:_combine_paths(base_path, endpoint_path)
  if not base_path or base_path == "" then
    return endpoint_path ~= "" and ("/" .. endpoint_path:gsub("^/", "")) or "/"
  end
  if not endpoint_path or endpoint_path == "" then
    return "/" .. base_path:gsub("^/", "")
  end

  local clean_base = base_path:gsub("^/", ""):gsub("/$", "")
  local clean_endpoint = endpoint_path:gsub("^/", "")

  if clean_endpoint == "" then
    return "/" .. clean_base
  end

  return "/" .. clean_base .. "/" .. clean_endpoint
end

return NestJsTreeSitterParser
