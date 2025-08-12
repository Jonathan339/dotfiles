-- lua/plugins/lsp/init.lua
local M = {
  'williamboman/mason.nvim',
  event = 'VeryLazy',
  cmd = { 'Mason', 'MasonInstall', 'MasonUpdate' },
  dependencies = {
    -- 🔴 Cargar lspconfig en el arranque para evitar carreras con auto_ensure
    { 'neovim/nvim-lspconfig', lazy = false },

    'williamboman/mason-lspconfig.nvim',

    -- UI de progreso LSP (API estable "legacy")
    { 'j-hui/fidget.nvim', tag = 'legacy', opts = { text = { done = '✓' }, window = { relative = 'win' } } },

    -- Mejor experiencia para lua_ls
    { 'folke/neodev.nvim', opts = { library = { plugins = { 'nvim-dap-ui' }, types = true } } },
  },
}

M.config = function()
  M.mason()
  M.mason_lspconfig() -- sin installer; auto_ensure hace instalaciones on-demand
end

-- Mason UI básico
M.mason = function()
  require('mason').setup({
    ui = {
      border = 'rounded',
      icons = {
        package_installed = '✓',
        package_pending = '➜',
        package_uninstalled = '✗',
      },
    },
  })
end

-- mason-lspconfig: compat con versiones nuevas/viejas
M.mason_lspconfig = function()
  local ok_mlsp, mlsp = pcall(require, 'mason-lspconfig')
  if not ok_mlsp then
    return
  end

  local ok_handlers, handlers = pcall(require, 'plugins.lsp.handlers')

  if type(mlsp.setup_handlers) == 'function' then
    mlsp.setup({})
    if ok_handlers then
      mlsp.setup_handlers(handlers)
    end
  else
    mlsp.setup({ handlers = ok_handlers and handlers or {} })
  end
end

return M
