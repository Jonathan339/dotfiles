-- lua/plugins/lspkind/init.lua
return {
  'onsails/lspkind.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = function()
    -- si tenés tus propios íconos:
    local custom = nil
    pcall(function()
      custom = require('utils.icons').lspkind
    end)

    return {
      mode = 'symbol_text', -- "text", "symbol", o "symbol_text"
      preset = 'default', -- o "codicons" si usás VSCode Codicons
      symbol_map = custom or {}, -- overrides opcionales
    }
  end,
  config = function(_, opts)
    require('lspkind').init(opts)
  end,
}
