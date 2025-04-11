local M = {
  'okuuva/auto-save.nvim',
  cmd = 'ASToggle',          -- optional for lazy loading on command
  -- event = { 'InsertLeave', 'TextChanged' }, -- optional for lazy loading on trigger events
  event = { 'InsertLeave' }, -- optional for lazy loading on trigger events
}

M.config = function()
  require('auto-save').setup({
    --debounce_delay = 1000,
  })
end

return M
