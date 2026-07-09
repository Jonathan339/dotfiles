local M = {
  'akinsho/toggleterm.nvim',
  version = '*',
  cmd = 'ToggleTerm',
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
      Normal = {
        guibg = '#252525',
        guifg = '#ffffff',
      },
      NormalFloat = {
        link = 'Normal',
      },
      FloatBorder = {
        guifg = '#8f45e3',
        guibg = '#252525',
      },
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
