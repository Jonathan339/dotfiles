local M = {
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
}

function M.config()
  require('oil').setup({
    float = {
      max_height = 20,
      max_width = 60,
    },
  })
end

return M
