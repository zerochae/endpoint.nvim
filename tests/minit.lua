vim.env.LAZY_STDPATH = ".tests"
load(vim.fn.system "curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua")()

-- Add absolute paths to Lua package path for tests
local current_dir = vim.fn.getcwd()
local lua_path = current_dir .. "/lua/?.lua"
local lua_init_path = current_dir .. "/lua/?/init.lua"
package.path = package.path .. ";" .. lua_path .. ";" .. lua_init_path

-- Store original package path globally for tests that need to change directories
_G.original_package_path = package.path

require("lazy.minit").setup {
  spec = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
}

require "plenary.busted"
