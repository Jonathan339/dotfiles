local M = {}

M.ensure_installed = {
  "bashls", "cssls", "custom_elements_ls", "diagnosticls", "dockerls", "efm",
  "eslint", "graphql", "html", "htmx", "jsonls", "lua_ls", "pyright", "rust_analyzer",
  "spectral", "sqlls", "ts_ls", "tailwindcss", "typos_lsp", "vimls", "vtsls", "vuels",
  "yamlls", "prettier", "stylelint", "shellcheck", "shfmt", "black", "isort", "stylua",
  "rubocop", "pint", "markdown",
}

local cmp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_ok then
  vim.notify("Error cargando cmp_nvim_lsp", vim.log.levels.ERROR)
  return M
end

M.capabilities = cmp_nvim_lsp.default_capabilities()
M.capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation", "detail", "additionalTextEdits",
    },
  },
}

M.on_init = function(client, _)
  if client.supports_method("textDocument/semanticTokens") then
    client.server_capabilities.semanticTokensProvider = nil
  end
end

M.on_attach = function(client, bufnr)
  if not client or not bufnr then return end
  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
  require("plugins.lsp.format").on_attach(client, bufnr)
end

M.root_dir = function(fname)
  local util = require("lspconfig").util
  return util.root_pattern(
    ".git", "tsconfig.base.json", "tsconfig.json", "package.json",
    ".eslintrc.js", ".eslintrc.json"
  )(fname)
end

return M
