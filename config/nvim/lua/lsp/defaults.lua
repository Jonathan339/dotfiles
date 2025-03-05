local M = {}
local u = require('utils')
local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
-- Función para manejo de errores y notificaciones
local function handle_error(msg, level)
  level = level or vim.log.levels.ERROR
  local trace = debug.traceback()
  vim.notify(msg .. '\n' .. trace, level)
end

-- Verificar la carga del módulo cmp_nvim_lsp y manejar el error
if not cmp_nvim_lsp_ok then
  handle_error('Error cargando cmp_nvim_lsp. Asegúrate de que el plugin esté instalado.')
  return M
end

local capabilities = cmp_nvim_lsp.default_capabilities()
local augroup_format = vim.api.nvim_create_augroup('LspFormatting', {})

-- Función para configurar opciones del buffer
local function buf_set_option(bufnr, name, value)
  vim.api.nvim_set_option_value(name, value, { buf = bufnr })
end

-- Función para formateo asincrónico
local function async_formatting(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  vim.schedule(function()
    vim.lsp.buf_request(bufnr, 'textDocument/formatting', vim.lsp.util.make_formatting_params({}),
      function(err, res, ctx)
        if err then
          handle_error('Error en el formateo: ' .. (type(err) == 'string' and err or err.message), vim.log.levels.WARN)
          return
        end

        if res then
          local client = vim.lsp.get_client_by_id(ctx.client_id)
          if not client then
            handle_error('Error al obtener el cliente LSP.')
            return
          end
          vim.lsp.util.apply_text_edits(res, bufnr, client.offset_encoding or 'utf-16')
          vim.api.nvim_buf_call(bufnr, function()
            vim.cmd('silent noautocmd update')
          end)
        else
          handle_error('No se recibieron resultados de formateo.', vim.log.levels.INFO)
        end
      end)
  end)
end

-- Función para habilitar formateo al guardar
local function enable_format_on_save(client, bufnr)
  if client.supports_method('textDocument/formatting') then
    vim.api.nvim_clear_autocmds({ group = augroup_format, buffer = bufnr })
    vim.api.nvim_create_autocmd('BufWritePost', {
      group = augroup_format,
      buffer = bufnr,
      callback = function()
        async_formatting(bufnr)
      end,
    })
  end
end

-- Función para habilitar hints en línea
local function enable_inlay_hints(client, bufnr)
  if client.server_capabilities.inlayHintProvider then
    vim.lsp.inlay_hint(bufnr, true)
  end
end

-- Función on_attach que se ejecuta cuando el servidor LSP se adjunta a un buffer
M.on_attach = function(client, bufnr)
  vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'

  if client.supports_method('textDocument/formatting') then
    enable_format_on_save(client, bufnr)
  end

  if client.supports_method('textDocument/publishDiagnostics') then
    vim.diagnostic.config({
      underline = true,
      virtual_text = {
        spacing = 5,
        severity_limit = 'Warning',
      },
      update_in_insert = true,
    }, bufnr)
  end

  if client.server_capabilities.inlayHintProvider then
    vim.lsp.inlay_hint(bufnr, true)
  end
end

-- Fusionar capacidades predeterminadas con configuraciones adicionales
M.capabilities = u.merge(capabilities, {
  workspace = {
    didChangeWatchedFiles = {
      dynamicRegistration = false,
    },
  },
})

-- Determinar el directorio raíz del proyecto
M.root_dir = function(fname)
  local util = require('lspconfig').util
  return util.root_pattern('.git', 'tsconfig.base.json', 'tsconfig.json', 'package.json', '.eslintrc.js',
    '.eslintrc.json')(fname)
end

return M
