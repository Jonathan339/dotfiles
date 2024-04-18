local M = {
  'okuuva/auto-save.nvim',
--  lazy = true,
  cmd = 'ASToggle',                         -- optional for lazy loading on command
  event = { 'InsertLeave', 'TextChanged' }, -- optional for lazy loading on trigger events
}

M.config = function()
  require('auto-save').setup()
end

return M
