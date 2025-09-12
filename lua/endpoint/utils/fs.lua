-- File system utilities
local M = {}

-- Check if a file exists
---@param filepath string
---@return boolean
function M.file_exists(filepath)
  local stat = vim.loop.fs_stat(filepath)
  return stat ~= nil and stat.type == "file"
end

-- Check if a directory exists
---@param dirpath string
---@return boolean
function M.dir_exists(dirpath)
  local stat = vim.loop.fs_stat(dirpath)
  return stat ~= nil and stat.type == "directory"
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

-- Get project name from root path
function M.get_project_name(root_path)
  root_path = root_path or M.get_project_root()
  return vim.fn.fnamemodify(root_path, ":t")
end

return M
