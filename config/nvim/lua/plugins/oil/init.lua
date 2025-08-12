local M = {
  'stevearc/oil.nvim',
  cmd = { 'Oil' },
  keys = {
    {
      '-',
      function()
        require('oil').open()
      end,
      desc = 'Oil: abrir directorio padre',
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
      default_file_explorer = true, -- reemplaza netrw
      columns = { 'icon', 'permissions', 'size', 'mtime' },
      delete_to_trash = true, -- requiere trash-cli o gio (opcional)
      skip_confirm_for_simple_edits = true,
      -- watch_for_changes = true,    -- si querés refresco automático (experimental)
      view_options = {
        show_hidden = false, -- toggle con g.
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
      use_default_keymaps = true, -- mantené defaults + los de arriba
    }
  end,
}

function M.config(_, opts)
  require('oil').setup(opts)
  -- atajos globales por si el plugin aún no cargó
  vim.keymap.set('n', '-', function()
    require('oil').open()
  end, { desc = 'Oil: abrir directorio padre' })
  vim.keymap.set('n', '<leader>e', function()
    require('oil').open_float()
  end, { desc = 'Oil: explorador flotante' })
end

return M
