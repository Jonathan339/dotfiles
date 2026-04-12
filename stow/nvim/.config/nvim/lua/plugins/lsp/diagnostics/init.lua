local ok, config = pcall(require, 'plugins.lsp.diagnostics.config')
if ok and config then
  vim.diagnostic.config(config)

  -- signos con íconos
  local signs = {
    Error = ' ',
    Warn = ' ',
    Hint = ' ',
    Info = ' ',
  }
  for type, icon in pairs(signs) do
    local hl = 'DiagnosticSign' .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
  end
end
