---@diagnostic disable: undefined-global
local M = {}

local group = vim.api.nvim_create_augroup('LspFormatting', { clear = true })

local function get_conform()
  local ok, conform = pcall(require, 'conform')
  if ok then
    return conform
  end
  return nil
end

M.on_attach = function(client, bufnr)
  -- Preferimos Conform cuando está disponible
  local conform = get_conform()

  -- Si usamos Conform, desactivamos el formateo del LSP para evitar doble formato
  if conform and client and client.server_capabilities then
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end

  -- Limpiamos cualquier autocmd previo de este buffer
  vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })

  -- Si Conform existe, no creamos autocmd acá (Conform ya maneja BufWritePre)
  if conform then
    return
  end

  -- Fallback: sin Conform, formateamos con LSP al guardar si el server lo soporta
  if client.supports_method('textDocument/formatting') then
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = group,
      buffer = bufnr,
      callback = function()
        pcall(vim.lsp.buf.format, { bufnr = bufnr, async = false, timeout_ms = 1000 })
      end,
    })
  end
end

return M
