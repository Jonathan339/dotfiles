local M = {}

local format_group = vim.api.nvim_create_augroup("LspFormatting", { clear = true })

M.on_attach = function(client, bufnr)
  if client.supports_method("textDocument/formatting") then
    vim.api.nvim_clear_autocmds({ group = format_group, buffer = bufnr })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = format_group,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ async = true })
      end,
    })
  end
end

return M
