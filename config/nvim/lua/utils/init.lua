local M = {}

M.setup_lsp = function(server, config)
  local defaults = require("plugins.lsp.defaults")
  local user_on_attach = config.on_attach
  config.on_attach = function(client, bufnr)
    if user_on_attach then
      user_on_attach(client, bufnr)
    end
    defaults.on_attach(client, bufnr)
  end

  vim.lsp.config(server, vim.tbl_deep_extend("force", {
    capabilities = defaults.capabilities,
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