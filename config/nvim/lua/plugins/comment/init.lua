local M = { 'numToStr/Comment.nvim', dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' } }

M.config = function()
  local Comment = require('Comment')
  local ft = require('Comment.ft')

  --1. Using method signature
  -- Set only line comment or both
  -- You can also chain the set calls
  ft.set('yaml', '#%s').set('javascript', { '//%s', '/*%s*/' })

  -- 2. Metatable magic
  ft.javascript = { '//%s', '/*%s*/' }
  ft.yaml = '#%s'

  -- 3. Multiple filetypes
  ft({ 'go', 'rust' }, { '//%s', '/*%s*/' })
  Comment.setup()
end

return M
