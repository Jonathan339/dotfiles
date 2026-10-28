-- lua/plugins/smart-splits/init.lua
local M = {
  'mrjones2014/smart-splits.nvim',
  event = 'VeryLazy',
  opts = {
    ignored_filetypes = { 'nofile', 'quickfix', 'qf', 'prompt' },
    ignored_buftypes = { 'nofile' },
    resize = { amount = 3 }, -- Nvim resize amount
  },
}

M.config = function(_, opts)
  local ss = require('smart-splits')
  ss.setup(opts)
end

return M