---@diagnostic disable: undefined-global, unused-local, unknown-symbol
local M = {
  'okuuva/auto-save.nvim',
  cmd = 'ASToggle', -- carga al usar el comando
  event = { 'InsertLeave', 'TextChanged' }, -- o cuando empezás a editar
  keys = {
    { '<leader>as', '<cmd>ASToggle<CR>', desc = 'Auto Save: toggle' },
  },
  opts = {
    enabled = true,
    debounce_delay = 800, -- ms; subilo si ves guardados muy seguidos
    -- Dejá el resto en defaults del plugin para evitar romper la API
  },
}

M.config = function(_, opts)
  local ok, autosave = pcall(require, 'auto-save')
  if not ok then
    return
  end
  autosave.setup(opts)

  -- (Opcional) muestra un aviso suave cuando toggles
  vim.api.nvim_create_user_command('ASNotify', function()
    local state = require('auto-save.config').opts.enabled and 'ON' or 'OFF'
    pcall(vim.notify, 'Auto Save: ' .. state)
  end, {})
  vim.api.nvim_create_autocmd('User', {
    pattern = 'AutoSaveToggleOn',
    callback = function()
      pcall(vim.notify, 'Auto Save: ON')
    end,
  })
  vim.api.nvim_create_autocmd('User', {
    pattern = 'AutoSaveToggleOff',
    callback = function()
      pcall(vim.notify, 'Auto Save: OFF')
    end,
  })
end

return M
