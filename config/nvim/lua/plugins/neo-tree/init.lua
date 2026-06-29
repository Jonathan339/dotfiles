return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = 'Neotree',

    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },

    opts = {
      popup_border_style = "rounded",
      filesystem = {
        filtered_items = {
          hide_dotfiles = true,
          hide_gitignored = false,
        },
      },

      -- window = {
      --   width = 35,
      -- },
    },
  },
}
