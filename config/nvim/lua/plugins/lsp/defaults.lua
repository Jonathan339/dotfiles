-- lua/plugins/lsp/defaults.lua
local M = {}

-- Capabilities: usar cmp_nvim_lsp si está; fallback a capabilities base
local ok_cmp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
local base_caps = vim.lsp.protocol.make_client_capabilities()
M.capabilities = ok_cmp and cmp_nvim_lsp.default_capabilities(base_caps) or base_caps

-- Ajustes finos de completionItem
M.capabilities.textDocument = M.capabilities.textDocument or {}
M.capabilities.textDocument.completion = M.capabilities.textDocument.completion or {}
M.capabilities.textDocument.completion.completionItem = vim.tbl_deep_extend('force', M.capabilities.textDocument.completion.completionItem or {}, {
  documentationFormat = { 'markdown', 'plaintext' },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = { 'documentation', 'detail', 'additionalTextEdits' },
  },
})

-- (Opcional) si usás plugins tipo ufo, añade foldingRange:
-- M.capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }

-- Desactivar semantic tokens global (evita choques visuales con Treesitter)
M.on_init = function(client, _)
  if client:supports_method('textDocument/semanticTokens') then
    client.server_capabilities.semanticTokensProvider = nil
  end
end

-- on_attach: formateo/keys/… lo delegamos a tu módulo
M.on_attach = function(client, bufnr)
  if not client or not bufnr then
    return
  end
  vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
  -- Usa tu lógica de formateo (fallback LSP si no hay Conform)
  pcall(function()
    require('plugins.lsp.format').on_attach(client, bufnr)
  end)
end

return M
