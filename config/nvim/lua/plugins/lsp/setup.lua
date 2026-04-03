local M = {}

function M.setup_lsp(server, config)
  local defaults = require('plugins.lsp.defaults')
  local lspconfig = require('lspconfig')

  lspconfig[server].setup(vim.tbl_deep_extend('force', {
    capabilities = defaults.capabilities,
    on_attach = defaults.on_attach,
    on_init = defaults.on_init,
  }, config or {}))
end

return M
