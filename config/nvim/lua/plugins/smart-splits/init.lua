-- https://github.com/mrjones2014/smart-splits.nvim
local M = {
  'mrjones2014/smart-splits.nvim',
  event = 'VeryLazy', -- load on very lazy for mux detection
  opts = {
    ignored_filetypes = { 'nofile', 'quickfix', 'qf', 'prompt' },
    ignored_buftypes = { 'nofile' },
  },

  config = function()
    require('smart-splits').setup({
      extensions = {
        smart_splits = {
          directions = { 'h', 'j', 'k', 'l' },
          mods = {
            move = '<C>', -- for moving cursor between windows
            resize = '<M>', -- for resizing windows
            swap = false, -- false disables creating a binding
          },
        },
      },
      -- Customize the mappings
      smart_splits = {
        mods = {
          swap = {
            mod = '<alt>',
            prefix = '<leader>',
          },
        },
      },
    })
  end,
}

return M
