local M = {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  dependencies = { 'hrsh7th/nvim-cmp', 'nvim-treesitter/nvim-treesitter' },
  opts = {
    fast_wrap = {},
    disable_filetype = { 'TelescopePrompt', 'vim' },
  },
}

M.config = function(_, opts)
  require('nvim-autopairs').setup(opts)
  -- If you want to automatically add `(` after selecting a function or method
  local cmp_autopairs = require('nvim-autopairs.completion.cmp')
  local cmp = require('cmp')
  cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
end

return M
