-- File system utilities
local M = {}

-- Check if a file exists (files only, excludes directories)
-- Use this when you need to ensure something is specifically a file
---@param filepath string
---@return boolean
function M.file_exists(filepath)
  local stat = vim.loop.fs_stat(filepath)
  return stat ~= nil and stat.type == "file"
end


-- Get the current working directory (project root)
---@return string
function M.get_project_root()
  local cwd = vim.fn.getcwd()

  -- In test environment, prefer current directory over git root
  -- Check if we're in a test fixture directory
  if cwd:match "tests/fixtures/" then
    return cwd
  end

  local result = vim.fn.system "git rev-parse --show-toplevel 2>/dev/null"
  if vim.v.shell_error ~= 0 then
    return cwd -- fallback to current directory
  end
  return (result:gsub("\n", ""))
end

-- Read file contents
---@param filepath string
---@return string[]?
function M.read_file(filepath)
  local ok, lines = pcall(vim.fn.readfile, filepath)
  if not ok or not lines then
    return nil
  end
  return lines
end


-- Check if any of the specified files/directories exist (readable files or accessible directories)
-- Use this for framework detection or general file/directory existence checks
-- For precise file-only checking, use file_exists()
---@param files string|string[] Single file path or list of file paths to check
---@return boolean True if at least one file or directory exists
function M.has_file(files)
  -- Handle single string parameter
  if type(files) == "string" then
    return vim.fn.filereadable(files) == 1 or vim.fn.isdirectory(files) == 1
  end

  -- Handle array parameter
  for _, file in ipairs(files) do
    if vim.fn.filereadable(file) == 1 or vim.fn.isdirectory(file) == 1 then
      return true
    end
  end
  return false
end

-- Escape special Lua pattern characters for literal string matching
-- This allows searching for strings with hyphens, dots, etc. without treating them as pattern syntax
---@param str string String to escape
---@return string Escaped string safe for use in Lua patterns
local function escape_pattern(str)
  return str:gsub("([%-%^%$%(%)%%%.%[%]%*%+%?])", "%%%1")
end

-- Check if a file contains specific pattern(s)
-- Use this for framework dependency detection in config files
-- Automatically escapes special pattern characters for literal string matching
---@param filepath string Path to the file to check
---@param patterns string|string[] Pattern(s) to search for (will be escaped for literal matching)
---@return boolean True if file exists and contains at least one pattern
function M.file_contains(filepath, patterns)
  if not M.has_file(filepath) then
    return false
  end

  local content = vim.fn.readfile(filepath)
  local file_str = table.concat(content, "\n")

  -- Handle single pattern
  if type(patterns) == "string" then
    local escaped_pattern = escape_pattern(patterns)
    return file_str:match(escaped_pattern) ~= nil
  end

  -- Handle multiple patterns (OR logic)
  for _, pattern in ipairs(patterns) do
    local escaped_pattern = escape_pattern(pattern)
    if file_str:match(escaped_pattern) then
      return true
    end
  end

  return false
end

-- Get cache directory path for the current project
---@param project_root? string Optional project root (defaults to current project)
---@return string Cache directory path
function M.get_cache_dir(project_root)
  project_root = project_root or M.get_project_root()
  local project_name = vim.fn.fnamemodify(project_root, ":t")
  return vim.fn.stdpath "data" .. "/endpoint.nvim/" .. project_name
end

-- Get filename from path (basename)
---@param filepath string Full file path
---@return string Filename only
function M.get_filename(filepath)
  return vim.fn.fnamemodify(filepath, ":t")
end

-- Get directory from path (dirname)
---@param filepath string Full file path
---@return string Directory path
function M.get_dirname(filepath)
  return vim.fn.fnamemodify(filepath, ":h")
end

-- Check if a directory exists
---@param dirpath string Directory path to check
---@return boolean True if directory exists
function M.is_directory(dirpath)
  return vim.fn.isdirectory(dirpath) == 1
end

-- Create directory (with parents)
---@param dirpath string Directory path to create
---@return boolean True if successful
function M.mkdir(dirpath)
  return vim.fn.mkdir(dirpath, "p") == 1
end

-- Delete file
---@param filepath string File path to delete
---@return boolean True if successful
function M.delete_file(filepath)
  return vim.fn.delete(filepath) == 0
end

return M
