-- lua/plugins/markdown/render-markdown.lua
local M = {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  ft = { 'markdown', 'quarto' },
}

M.config = function()
  -- Highlights “amigables con cualquier tema”
  vim.api.nvim_set_hl(0, 'render-markdownBullet', { link = 'Special', default = true })

  -- Los ajustes de buffer (wrap/spell/conceallevel) viven en config/autocmd.lua

  -- render-markdown ignora internamente los archivos que superan
  -- max_file_size; usamos la misma política que el resto de la config.
  local large_file_mb = require('utils').large_file_size / 1024 / 1024

  -- Config básica del plugin (segura)
  require('render-markdown').setup({
    max_file_size = large_file_mb,
    anti_conceal = {
      enabled = true,
      ignore = {
        code_background = true,
        sign = true,
      },
      above = 0,
      below = 0,
    },
    -- Muestra/oculta según modo (normal/insert); útil para edición
    render_modes = true,
    heading = {
      enabled = true,
      sign = true,
      style = 'full',
      icons = { '① ', '② ', '③ ', '④ ', '⑤ ', '⑥ ' },
      left_pad = 1,
    },
    bullet = {
      enabled = true,
      icons = { '●', '○', '◆', '◇' },
      right_pad = 1,
      highlight = 'render-markdownBullet',
    },
  })
end

return M
