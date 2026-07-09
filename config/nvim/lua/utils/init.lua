local M = {}
local has_lsp_config = pcall(function() return vim.lsp.config end)

M.setup_lsp = function(server, config)
  local defaults = require("plugins.lsp.defaults")
  local user_on_attach = config.on_attach
  config.on_attach = function(client, bufnr)
    if user_on_attach then
      user_on_attach(client, bufnr)
    end
    defaults.on_attach(client, bufnr)
  end

  local opts = vim.tbl_deep_extend("force", {
    capabilities = defaults.capabilities,
    on_init = defaults.on_init,
  }, config)

  if has_lsp_config then
    vim.lsp.config(server, opts)
  else
    local lspconfig = require("lspconfig")
    lspconfig[server].setup(opts)
  end
end

local function map(mode, lhs, rhs, opts)
  local default_opts = {
    desc = "",
    noremap = true,
    silent = true,
  }

  if opts then
    for k, v in pairs(opts) do
      default_opts[k] = v
    end
  end

  vim.keymap.set(mode, lhs, rhs, default_opts)
end

M.map = map

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