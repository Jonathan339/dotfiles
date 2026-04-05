local M = {}
-- local defaults = require("plugins.lsp.defaults")
-- local lspconfig = require("lspconfig")

M.setup_lsp = function(server, config)
  lspconfig[server].setup(vim.tbl_deep_extend("force", {
    capabilities = defaults.capabilities,
    on_attach = defaults.on_attach,
    on_init = defaults.on_init,
  }, config))
end

M.map = function(mode, lhs, rhs, opts)
  vim.keymap.set(
    mode,
    lhs,
    rhs,
    vim.tbl_deep_extend("force", { silent = true, noremap = true }, opts or {})
  )
end

M.create_buf_map = function(bufnr, opts)
  return function(mode, lhs, rhs, map_opts)
    M.map(
      mode,
      lhs,
      rhs,
      vim.tbl_deep_extend("force", { buffer = bufnr }, opts or {}, map_opts or {})
    )
  end
end

return M