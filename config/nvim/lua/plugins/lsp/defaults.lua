-- lua/plugins/lsp/defaults.lua
local M = {}

-- Esta lista es para mason-tool-installer (IDs de Mason, no nombres de lspconfig)
M.ensure_installed = {
  -- ===== LSP servers =====
  'bash-language-server',
  'css-lsp',
  'custom-elements-languageserver', -- si no lo usás, podés quitarlo
  'dockerfile-language-server',
  'efm',
  'vscode-eslint-language-server',
  'graphql-language-service-cli',
  'html-lsp',
  'htmx-lsp', -- opcional
  'json-lsp',
  'lua-language-server',
  'pyright',
  'rust-analyzer',
  'spectral-language-server', -- OpenAPI linter LSP (opcional)
  'sqls',
  'typescript-language-server', -- para lspconfig "ts_ls"
  'tailwindcss-language-server',
  'typos-lsp',
  'vim-language-server',
  'vtsls', -- alternativa a ts_ls
  'vls', -- Vue (vuels). Alternativa moderna: "vue-language-server" (Volar)
  'yaml-language-server',
  'marksman', -- Markdown LSP

  -- ===== Formatters / Linters / Tools =====
  'prettier',
  'prettierd',
  'stylelint', -- CLI; si querés LSP: "stylelint-lsp"
  'shellcheck',
  'shfmt',
  'black',
  'isort',
  'stylua',
  'rubocop',
  'pint',
  'dprint',
  'fixjson',
  'autopep8',
  'goimports', -- si tu registry no lo tiene, usa "goimports-reviser"
  'goimports-reviser',
  'gofumpt',
}

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
  if client.supports_method('textDocument/semanticTokens') then
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

-- Root genérico (útil para la mayoría de servidores)
M.root_dir = function(fname)
  local match = vim.fs.find({
    '.git',
    'tsconfig.base.json',
    'tsconfig.json',
    'package.json',
    '.eslintrc.js',
    '.eslintrc.cjs',
    '.eslintrc.json',
    '.eslintrc.yaml',
    '.eslintrc.yml',
    'eslint.config.js',
    'eslint.config.cjs',
    'eslint.config.mjs',
    'eslint.config.ts',
  }, { path = fname, upward = true })[1]
  return match and vim.fs.dirname(match) or nil
end

return M
