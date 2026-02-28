local M = {
  'stevearc/oil.nvim',
  cmd = { 'Oil' },
  keys = {
    {
      '-',
      function()
        require('oil').open()
      end,
      desc = 'Oil: abrir dir padre',
    },
    {
      '<leader>e',
      function()
        require('oil').open_float()
      end,
      desc = 'Oil: explorador flotante',
    },
  },
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = function()
    return {
      default_file_explorer = true,
      columns = { 'icon', 'permissions', 'size', 'mtime' },
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      view_options = {
        show_hidden = false,
        natural_order = true,
        sort = { { 'type', 'asc' }, { 'name', 'asc' } },
        is_always_hidden = function(name, _)
          return name == '.git' or name == 'node_modules' or name == '.cache'
        end,
      },
      float = {
        padding = 2,
        max_width = 0.9,
        max_height = 0.9,
        border = 'rounded',
        win_options = { winblend = 0, signcolumn = 'no' },
      },
      keymaps = {
        ['g?'] = 'actions.show_help',
        ['<CR>'] = 'actions.select',
        ['q'] = 'actions.close',
        ['-'] = 'actions.parent',
        ['_'] = 'actions.open_cwd',
        ['`'] = 'actions.cd',
        ['~'] = 'actions.tcd',
        ['gx'] = 'actions.open_external',
        ['gp'] = 'actions.preview',
        ['gs'] = 'actions.change_sort',
        ['g.'] = 'actions.toggle_hidden',
      },
      use_default_keymaps = true,
    }
  end,
}

M.config = function(_, opts)
  require('oil').setup(opts)
  -- 🔕 quitá estos mapeos si ya usás 'keys' arriba
  -- vim.keymap.set("n", "-", function() require("oil").open() end, { desc = "Oil: abrir dir padre" })
  -- vim.keymap.set("n", "<leader>e", function() require("oil").open_float() end, { desc = "Oil: explorador flotante" })
end

return M
