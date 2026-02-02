-- Tree-sitter based endpoint parser for endpoint.nvim
-- Uses AST queries for accurate endpoint detection
local class = require "endpoint.lib.middleclass"
local Parser = require "endpoint.core.Parser"
local log = require "endpoint.utils.log"

---@class endpoint.core.TreeSitterParser : endpoint.Parser
local TreeSitterParser = class("TreeSitterParser", Parser)

function TreeSitterParser:initialize(fields)
  Parser.initialize(self, fields or {})
  self.parser_name = fields and fields.parser_name or "treesitter_parser"
  self.language = fields and fields.language or "unknown"
  self.queries = fields and fields.queries or {}
end

---Check if Tree-sitter is available for the given language
---@param lang string Language name (java, typescript, python, etc.)
---@return boolean
function TreeSitterParser:is_treesitter_available(lang)
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return false
  end

  return parsers.has_parser(lang)
end

---Get Tree-sitter parser for a language
---@param lang string Language name
---@return userdata|nil parser
function TreeSitterParser:get_ts_parser(lang)
  if not self:is_treesitter_available(lang) then
    return nil
  end

  local ok, parser = pcall(vim.treesitter.get_parser, 0, lang)
  if not ok then
    return nil
  end

  return parser
end

---Parse file content using Tree-sitter
---@param file_path string Path to the file
---@param lang string Language name
---@return userdata|nil tree
function TreeSitterParser:parse_file(file_path, lang)
  -- Read file content
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return nil
  end

  local content = table.concat(lines, "\n")

  -- Get language parser
  local parser_ok, parser = pcall(vim.treesitter.get_string_parser, content, lang)
  if not parser_ok or not parser then
    return nil
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return nil
  end

  return trees[1], content, lines
end

---Run a Tree-sitter query on content
---@param content string File content
---@param lang string Language name
---@param query_string string Tree-sitter query
---@return table[] captures Array of {node, name, text}
function TreeSitterParser:run_query(content, lang, query_string)
  local captures = {}

  -- Parse content
  local parser_ok, parser = pcall(vim.treesitter.get_string_parser, content, lang)
  if not parser_ok or not parser then
    log.framework_debug("Failed to create parser for: " .. lang)
    return captures
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return captures
  end

  local tree = trees[1]
  local root = tree:root()

  -- Create and run query
  local query_ok, query = pcall(vim.treesitter.query.parse, lang, query_string)
  if not query_ok or not query then
    log.framework_debug("Failed to parse query for: " .. lang)
    return captures
  end

  for id, node, _ in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]
    local text = vim.treesitter.get_node_text(node, content)
    local start_row, start_col, end_row, end_col = node:range()

    table.insert(captures, {
      node = node,
      name = name,
      text = text,
      start_row = start_row,
      start_col = start_col,
      end_row = end_row,
      end_col = end_col,
    })
  end

  return captures
end

---Extract endpoints from file using Tree-sitter queries
---@param file_path string Path to the file
---@param options table|nil Options
---@return table[] endpoints
function TreeSitterParser:extract_endpoints_from_file(file_path, options)
  options = options or {}
  local endpoints = {}

  -- Determine language from file extension
  local lang = self:detect_language(file_path)
  if not lang then
    return endpoints
  end

  -- Check if Tree-sitter parser is available
  if not self:is_treesitter_available(lang) then
    log.framework_debug("Tree-sitter parser not available for: " .. lang)
    return endpoints
  end

  -- Read file content
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return endpoints
  end
  local content = table.concat(lines, "\n")

  -- Get query for this language
  local query_string = self:get_query_for_language(lang)
  if not query_string then
    log.framework_debug("No query defined for: " .. lang)
    return endpoints
  end

  -- Run query and extract endpoints
  local captures = self:run_query(content, lang, query_string)
  endpoints = self:process_captures(captures, file_path, content, options)

  return endpoints
end

---Detect language from file path
---@param file_path string
---@return string|nil
function TreeSitterParser:detect_language(file_path)
  local ext_map = {
    java = "java",
    kt = "kotlin",
    ts = "typescript",
    tsx = "tsx",
    js = "javascript",
    jsx = "javascript",
    py = "python",
    rb = "ruby",
    php = "php",
    cs = "c_sharp",
  }

  local ext = file_path:match "%.([^.]+)$"
  return ext and ext_map[ext]
end

---Get Tree-sitter query for a language
---@param lang string
---@return string|nil
function TreeSitterParser:get_query_for_language(lang)
  return self.queries[lang]
end

---Process captured nodes into endpoints
---@param captures table[] Captured nodes
---@param file_path string File path
---@param content string File content
---@param options table Options
---@return table[] endpoints
function TreeSitterParser:process_captures(captures, file_path, content, options)
  -- To be overridden by framework-specific implementations
  return {}
end

---Override: Not applicable for Tree-sitter (we parse whole files)
function TreeSitterParser:extract_base_path()
  return ""
end

---Override: Not applicable for Tree-sitter
function TreeSitterParser:extract_endpoint_path()
  return nil
end

---Override: Not applicable for Tree-sitter
function TreeSitterParser:extract_method()
  return "GET"
end

---Override: Tree-sitter specific content validation
function TreeSitterParser:is_content_valid_for_parsing(content)
  return content ~= nil and content ~= ""
end

---Override: Higher confidence for Tree-sitter parsing
function TreeSitterParser:get_parsing_confidence()
  return 0.95 -- Tree-sitter AST parsing is highly accurate
end

return TreeSitterParser
