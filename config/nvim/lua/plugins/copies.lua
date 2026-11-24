return {
  "LudovicChenot/copy.lua",
  git = "https://github.com/LudovicChenot/copy.lua.git",
  event = "VeryLazy",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("copy").setup({})
  end,
}
