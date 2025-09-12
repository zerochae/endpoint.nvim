vim.env.LAZY_STDPATH = ".tests"
load(vim.fn.system "curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua")()

-- Add absolute paths to Lua package path for tests
local current_dir = vim.fn.getcwd()
package.path = package.path .. ";" .. current_dir .. "/lua/?.lua" .. ";" .. current_dir .. "/lua/?/init.lua"

require("lazy.minit").setup {
  spec = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
}

require "plenary.busted"
