-- File system utility functions
local M = {}

-- Check if a file exists (files only, excludes directories)
-- Use this when you need to ensure something is specifically a file
function M.file_exists(target_file_path)
  local file_stat = vim.loop.fs_stat(target_file_path)
  return file_stat ~= nil and file_stat.type == "file"
end

-- Get the current working directory (project root)
function M.get_project_root()
  local current_working_directory = vim.fn.getcwd()

  -- In test environment, prefer current directory over git root
  -- Check if we're in a test fixture directory
  if current_working_directory:match "tests/fixtures/" then
    return current_working_directory
  end

  local git_root_result = vim.fn.system "git rev-parse --show-toplevel 2>/dev/null"
  if vim.v.shell_error ~= 0 then
    return current_working_directory -- fallback to current directory
  end
  return (git_root_result:gsub("\n", ""))
end

-- Read file contents
function M.read_file(target_file_path)
  local read_success, file_content_lines = pcall(vim.fn.readfile, target_file_path)
  if not read_success or not file_content_lines then
    return nil
  end
  return file_content_lines
end

-- Check if any of the specified files/directories exist (readable files or accessible directories)
-- Use this for framework detection or general file/directory existence checks
-- For precise file-only checking, use file_exists()
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
local function escape_pattern(str)
  return (str:gsub("([%-%^%$%(%)%%%.%[%]%*%+%?])", "%%%1"))
end

-- Check if a file contains specific pattern(s)
-- Use this for framework dependency detection in config files
-- Automatically escapes special pattern characters for literal string matching
function M.file_contains(filepath, patterns)
  if not M.has_file(filepath) then
    return false
  end

  -- Check if it's actually a file, not a directory
  if not M.file_exists(filepath) then
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
function M.get_cache_dir(project_root)
  project_root = project_root or M.get_project_root()
  local project_name = vim.fn.fnamemodify(project_root, ":t")
  return vim.fn.stdpath "data" .. "/endpoint.nvim/" .. project_name
end

-- Get filename from path (basename)
function M.get_filename(filepath)
  return vim.fn.fnamemodify(filepath, ":t")
end

-- Get directory from path (dirname)
function M.get_dirname(filepath)
  return vim.fn.fnamemodify(filepath, ":h")
end

-- Check if a directory exists
function M.is_directory(dirpath)
  return vim.fn.isdirectory(dirpath) == 1
end

-- Create directory (with parents)
function M.mkdir(dirpath)
  return vim.fn.mkdir(dirpath, "p") == 1
end

-- Delete file
function M.delete_file(filepath)
  return vim.fn.delete(filepath) == 0
end

return M
