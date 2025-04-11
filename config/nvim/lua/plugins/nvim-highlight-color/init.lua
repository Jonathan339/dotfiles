local M = {
  'brenoprata10/nvim-highlight-colors',
}

function M.config()
  require('nvim-highlight-colors').setup({
    render = 'background', -- estilo de renderizado
    enable_hex = true, -- habilitar colores hexadecimales
    enable_rgb = true, -- habilitar colores RGB
    enable_hsl = true, -- habilitar colores HSL
    enable_var_usage = true, -- habilitar variables CSS
    enable_named_colors = true, -- habilitar nombres de colores
    custom_colors = { -- personalizar colores específicos
      { label = '%-%-theme%-primary%-color', color = '#0f1219' },
      { label = '%-%-theme%-secondary%-color', color = '#5a5d64' },
    },
    exclude_filetypes = {}, -- tipos de archivo excluidos
    exclude_buftypes = {}, -- tipos de buffer excluidos
  })
end

return M
