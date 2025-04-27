local M = {
  'ricardoraposo/gruvbox-minor.nvim',
  lazy = false,
  priority = 1000,
  opts = {},
}

M.config = function()
  vim.cmd.colorscheme('gruvbox-minor')
end

return M
