vim.env.LAZY_STDPATH = ".tests"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

require("lazy.minit").setup({
  spec = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
})

require("plenary.busted")
