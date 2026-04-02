-- lua/plugins/smart-splits/init.lua
local M = {
  'mrjones2014/smart-splits.nvim',
  enabled = function()
    return vim.fn.has('nvim-0.10') == 1
  end,
  event = 'VeryLazy',
  opts = {
    ignored_filetypes = { 'nofile', 'quickfix', 'qf', 'prompt' },
    ignored_buftypes = { 'nofile' },
    default_amount = 3, -- px/cols por resize
  },
}

M.config = function(_, opts)
  local ok_ss, ss = pcall(require, 'smart-splits')
  if not ok_ss then
    return
  end
  ss.setup(opts)

  -- Ejemplo de keymaps: Ctrl-h/j/k/l para moverse entre splits
  vim.keymap.set('n', '<C-h>', ss.move_cursor_left, { desc = 'Mover a split izquierda' })
  vim.keymap.set('n', '<C-j>', ss.move_cursor_down, { desc = 'Mover a split abajo' })
  vim.keymap.set('n', '<C-k>', ss.move_cursor_up, { desc = 'Mover a split arriba' })
  vim.keymap.set('n', '<C-l>', ss.move_cursor_right, { desc = 'Mover a split derecha' })

  -- Alt + h/j/k/l para redimensionar
  vim.keymap.set('n', '<M-h>', ss.resize_left, { desc = 'Resize split izquierda' })
  vim.keymap.set('n', '<M-j>', ss.resize_down, { desc = 'Resize split abajo' })
  vim.keymap.set('n', '<M-k>', ss.resize_up, { desc = 'Resize split arriba' })
  vim.keymap.set('n', '<M-l>', ss.resize_right, { desc = 'Resize split derecha' })

  -- Opcional: swap splits con leader+H/J/K/L
  vim.keymap.set('n', '<leader>wh', ss.swap_buf_left, { desc = 'Swap split izquierda' })
  vim.keymap.set('n', '<leader>wj', ss.swap_buf_down, { desc = 'Swap split abajo' })
  vim.keymap.set('n', '<leader>wk', ss.swap_buf_up, { desc = 'Swap split arriba' })
  vim.keymap.set('n', '<leader>wl', ss.swap_buf_right, { desc = 'Swap split derecha' })
end

return M
