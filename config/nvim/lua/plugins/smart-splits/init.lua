-- lua/plugins/smart-splits/init.lua
local M = {
  'mrjones2014/smart-splits.nvim',
  event = 'VeryLazy',
  opts = {
    ignored_filetypes = { 'nofile', 'quickfix', 'qf', 'prompt' },
    ignored_buftypes = { 'nofile' },
    -- desde v1 `default_amount` se movió a `resize.amount`
    resize = { amount = 3 },
  },
}

M.config = function(_, opts)
  local ss = require('smart-splits')
  ss.setup(opts)
end

return M
