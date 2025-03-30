local M = {}
-- ===========================
--    SERVIDORES A INSTALAR
-- ===========================
M.ensure_installed = {
  "bashls", "cssls", "custom_elements_ls", "diagnosticls", "dockerls", "efm", "eslint",
  "graphql", "html", "htmx", "jsonls", "lua_ls", "pyright", "rust_analyzer", "spectral",
  "sqlls", "ts_ls", "tailwindcss", "typos_lsp", "vimls", "vtsls", "vuels", "yamlls",
  "prettier", "stylelint", "shellcheck", "shfmt", "black", "isort", "gofmt", "stylua",
  "rubocop", "pint",
}

-- ===========================
-- CARGAR cmp_nvim_lsp
-- ===========================
local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
if not cmp_nvim_lsp_ok then
  vim.notify('Error cargando cmp_nvim_lsp. Asegúrate de que el plugin esté instalado.', vim.log.levels.ERROR)
  return M
end
M.capabilities = cmp_nvim_lsp.default_capabilities()

-- ===========================
--        LSP SETUP
-- ===========================
-- Función de on_attach para configurar LSP
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
M.on_attach = function(client, bufnr)
  if not client or not bufnr then
    vim.notify('LSP on_attach: Client o buffer inválido', vim.log.levels.ERROR)
    return
  end

  -- Establecer función omnifunc para autocompletado
  vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'

  -- Formateo en guardar, si el servidor lo soporta
  if client.supports_method("textDocument/formatting") then
    vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup,
      buffer = bufnr,
      callback = function()
        -- Hacer el formateo si no está deshabilitado
        if not vim.b._formatting_disabled then
          require("lsp-format").on_attach(client, bufnr)
        end
      end,
    })
  end
end

-- Función para detectar el directorio raíz del proyecto
M.root_dir = function(fname)
  local util = require('lspconfig').util
  return util.root_pattern('.git', 'tsconfig.base.json', 'tsconfig.json', 'package.json',
    '.eslintrc.js', '.eslintrc.json')(fname)
end

return M
