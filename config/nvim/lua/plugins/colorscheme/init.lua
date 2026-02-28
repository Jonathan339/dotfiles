local M = {
  'ricardoraposo/gruvbox-minor.nvim',
  lazy = false, -- carga inmediata
  priority = 1000, -- asegura que se aplique antes que otros
  opts = {
    -- ejemplo de overrides disponibles:
    -- transparent = true,
    -- bold = true,
    -- italics = true,
  },
  config = function(_, opts)
    require('gruvbox-minor').setup(opts)
    vim.cmd.colorscheme('gruvbox-minor')
  end,
}

return M
