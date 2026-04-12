---@diagnostic disable: undefined-global
return {
  'obsidian-nvim/obsidian.nvim',
  version = '*',
  lazy = true,
  ft = 'markdown',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'hrsh7th/nvim-cmp',
    'nvim-telescope/telescope.nvim',
    {
      'iamcco/markdown-preview.nvim',
      build = 'cd app && npm install',
      ft = 'markdown',
      init = function()
        vim.g.mkdp_auto_start = 0
        vim.g.mkdp_auto_close = 1
        vim.g.mkdp_refresh_slow = 0
        vim.g.mkdp_open_to_the_world = 0
      end,
    },
  },
  opts = {
    ui = { enable = true }, -- activamos para mejor vista
    legacy_commands = false,
    workspaces = {
      {
        name = '~/MEGA',
        path = vim.fn.expand('~/MEGA/Obsidian/'),
      },
    },
    completion = {
      nvim_cmp = true,
    },
    mappings = {},
  },
  config = function(_, opts)
    vim.o.conceallevel = 1 -- necesario para el formato de Obsidian

    local obsidian = require('obsidian')
    obsidian.setup(opts)

    -- Atajos
    vim.keymap.set('n', '<leader>on', ':ObsidianNew<CR>', { desc = 'Nueva nota' })
    vim.keymap.set('n', '<leader>os', ':ObsidianSearch<CR>', { desc = 'Buscar nota' })
    vim.keymap.set('n', '<leader>oo', ':ObsidianOpen<CR>', { desc = 'Abrir en Obsidian App' })
    vim.keymap.set('n', '<leader>mp', ':MarkdownPreviewToggle<CR>', { desc = 'Vista previa Markdown' })
  end,
}
