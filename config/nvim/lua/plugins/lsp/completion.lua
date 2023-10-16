return {
  "hrsh7th/nvim-cmp",
  dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-git",
      "saadparwaiz1/cmp_luasnip",
      "onsails/lspkind-nvim",
      { "L3MON4D3/LuaSnip", version = "v1.*" },
      "windwp/nvim-autopairs",
      {
          "zbirenbaum/copilot-cmp",
          dependencies = {
              "zbirenbaum/copilot.lua",
          },
          cmd = { "Copilot" },
          event = { "VeryLazy" },
          opts = {
              suggestion = { enabled = false },
              panel = { enabled = false },
          },
      },
  },
  config = function()
      require "alpha.completion"
  end,
}