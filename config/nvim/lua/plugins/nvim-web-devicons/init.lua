local M = {
  'nvim-tree/nvim-web-devicons',
  event = 'VeryLazy',
}
M.config = function()
  require('nvim-web-devicons').setup()
end
return M
