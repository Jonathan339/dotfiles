-- lua/plugins/lspkind/init.lua
return {
  'onsails/lspkind.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    mode = 'symbol_text',
    preset = 'default',
  },
  config = function(_, opts)
    require('lspkind').init(opts)
  end,
}
