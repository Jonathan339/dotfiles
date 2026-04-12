local M = {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = true,
}

M.config = function()
  local term = require('toggleterm')

  term.setup({
    direction = 'float', --'vertical' | 'horizontal' | 'tab' | 'float',
    float_opts = {
      -- The border key is *almost* the same as 'nvim_open_win'
      -- see :h nvim_open_win for details on borders however
      -- the 'curved' border is a custom border type
      -- not natively supported but implemented in this plugin.
      border = 'curved', -- 'single' | 'double' | 'shadow' | 'curved' | ...,
    },
    highlights = {
      -- Resaltado para el texto normal dentro de la terminal
      Normal = {
        guibg = '#ffffff', -- Color de fondo del texto normal
        guifg = '#000000', -- Color del texto normal
      },
      -- Resaltado para el texto normal dentro de una ventana flotante
      NormalFloat = {
        link = 'Normal', -- Enlace al resaltado de texto normal
      },
      -- Resaltado para el borde de la ventana flotante
      -- FloatBorder = {
      --   guifg = '#ff0000', -- Color del borde de la ventana flotante
      --   guibg = '#000000', -- Color de fondo del borde de la ventana flotante
      -- },
      -- Agrega más resaltados según sea necesario...
    },
    winbar = {
      enabled = false,
      name_formatter = function(term) --  term: Terminal
        return term.name
      end,
    },
  })
end

return M
