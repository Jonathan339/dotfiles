-- lua/plugins/smart-splits/init.lua
local M = {
  'mrjones2014/smart-splits.nvim',
  event = 'VeryLazy',
  opts = {
    ignored_filetypes = { 'nofile', 'quickfix', 'qf', 'prompt' },
    ignored_buftypes = { 'nofile' },
    default_amount = 3, -- px/cols por resize
  },
}

M.config = function(_, opts)
  local ss = require('smart-splits')
  ss.setup(opts)
end

return M
